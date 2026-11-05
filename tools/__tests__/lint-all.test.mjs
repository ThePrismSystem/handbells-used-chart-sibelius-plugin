import { test, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { chmodSync, existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { ROOT, TOOLS, findExe, main, spawnOptions, tracked } from '../lint-all.mjs';

const dirs = [];

function tempDir() {
    const dir = mkdtempSync(join(tmpdir(), 'hbuc-lint-'));
    dirs.push(dir);
    return dir;
}

afterEach(() => {
    while (dirs.length > 0) rmSync(dirs.pop(), { recursive: true, force: true });
});

function fakeTool(name, { found = true, passes = true, calls = [] } = {}) {
    return {
        name,
        find: () => (found ? `/bin/${name}` : null),
        install: `install ${name} somehow`,
        run: (exe, sarifDir) => {
            calls.push({ exe, sarifDir });
            return passes;
        }
    };
}

function logged(t) {
    const log = t.mock.method(console, 'log', () => {});
    return () => log.mock.calls.map((call) => call.arguments.join(' ')).join('\n');
}

// An executable that records the arguments it was given, one JSON line per
// call, and exits with the given status.
function fakeExe(status = 0) {
    const dir = tempDir();
    const exe = join(dir, 'fake');
    const record = join(dir, 'calls.jsonl');
    writeFileSync(exe, `#!/usr/bin/env node
require('fs').appendFileSync(${JSON.stringify(record)}, JSON.stringify(process.argv.slice(2)) + '\\n');
process.exit(${status});
`);
    chmodSync(exe, 0o755);
    const calls = () => readFileSync(record, 'utf8').trim().split('\n').map((line) => JSON.parse(line));
    return { exe, calls };
}

const tool = (name) => TOOLS.find((t) => t.name === name);

test('passes when every tool passes', (t) => {
    const output = logged(t);
    assert.equal(main([], [fakeTool('a'), fakeTool('b')]), 0);
    assert.match(output(), /PASS {2}a\nPASS {2}b\nALL PASS$/);
});

test('fails when a tool fails', (t) => {
    const output = logged(t);
    assert.equal(main([], [fakeTool('a'), fakeTool('b', { passes: false })]), 1);
    assert.match(output(), /FAIL {2}b\nSOME FAILED$/);
});

test('skips a missing tool unless strict', (t) => {
    const output = logged(t);
    assert.equal(main([], [fakeTool('a'), fakeTool('b', { found: false })]), 0);
    assert.match(output(), /SKIP {2}b: b not found\. install b somehow/);
    assert.match(output(), /ALL PASS \(1 skipped\)$/);

    assert.equal(main(['--strict'], [fakeTool('a'), fakeTool('b', { found: false })]), 1);
    assert.match(output(), /FAIL {2}b: b not found\. install b somehow/);
});

test('rejects an unknown argument or tool', (t) => {
    const output = logged(t);
    assert.equal(main(['--bogus'], [fakeTool('a')]), 2);
    assert.match(output(), /unknown argument: --bogus/);
    assert.equal(main(['--only', 'nope'], [fakeTool('a')]), 2);
    assert.match(output(), /unknown tool: nope/);
});

test('runs only the tools named', (t) => {
    logged(t);
    const aCalls = [];
    const bCalls = [];
    assert.equal(main(['--only', 'b'], [fakeTool('a', { calls: aCalls }), fakeTool('b', { calls: bCalls })]), 0);
    assert.equal(aCalls.length, 0);
    assert.equal(bCalls.length, 1);
});

test('creates the SARIF folder and hands the tools its absolute path', (t) => {
    logged(t);
    const sarif = join(tempDir(), 'nested', 'sarif');
    const calls = [];
    main(['--sarif', sarif], [fakeTool('a', { calls })]);
    assert.ok(existsSync(sarif));
    assert.deepEqual(calls, [{ exe: '/bin/a', sarifDir: sarif }]);
});

test('tracked lists files git tracks', () => {
    assert.deepEqual(tracked(['package.json']), ['package.json']);
});

test('tracked throws when git fails', () => {
    assert.throws(() => tracked(['package.json'], tempDir()), /git ls-files failed/);
});

test('findExe finds a file in the given folders and nothing else', () => {
    const dir = tempDir();
    writeFileSync(join(dir, 'fake'), '');
    assert.equal(findExe('fake', [dir]), join(dir, 'fake'));
    assert.equal(findExe('nope', [dir]), null);
});

test('spawns a .cmd shim through a shell', () => {
    assert.equal(spawnOptions('eslint.cmd').shell, true);
    assert.equal(spawnOptions('ESLINT.CMD').shell, true);
    assert.equal(spawnOptions('/usr/bin/eslint').shell, false);
    assert.equal(spawnOptions('eslint', { stdio: 'pipe' }).stdio, 'pipe');
});

test('the tools run in order: manuscript, eslint, zizmor, gitleaks', () => {
    assert.deepEqual(TOOLS.map((t) => t.name), ['manuscript', 'eslint', 'zizmor', 'gitleaks']);
    assert.equal(tool('manuscript').find(), process.execPath);
});

test('the manuscript tool passes on this repo', () => {
    assert.equal(tool('manuscript').run(process.execPath, null), true);
});

test('eslint checks every tracked .mjs file with no warnings allowed', { skip: process.platform === 'win32' }, () => {
    const { exe, calls } = fakeExe();
    assert.equal(tool('eslint').run(exe, null), true);
    const [args] = calls();
    assert.deepEqual(args.slice(0, 3), ['--max-warnings', '0', '--no-warn-ignored']);
    assert.ok(args.includes('tools/build.mjs'));
    assert.ok(args.slice(3).every((file) => file.endsWith('.mjs')));
});

test('a tool that exits non-zero fails', { skip: process.platform === 'win32' }, () => {
    const { exe } = fakeExe(1);
    assert.equal(tool('eslint').run(exe, null), false);
});

test('zizmor checks the workflows, and writes SARIF when asked', { skip: process.platform === 'win32' }, () => {
    const { exe, calls } = fakeExe();
    const sarif = tempDir();
    assert.equal(tool('zizmor').run(exe, sarif), true);
    const [plain, asSarif] = calls();
    assert.ok(plain.includes('.github/workflows/test.yml'));
    assert.ok(plain.every((file) => file.startsWith('.github/workflows/') && file.endsWith('.yml')));
    assert.deepEqual(asSarif, ['--format', 'sarif', ...plain]);
    assert.ok(existsSync(join(sarif, 'zizmor.sarif')));
});

test('gitleaks scans the history, and writes SARIF when asked', { skip: process.platform === 'win32' }, () => {
    const { exe, calls } = fakeExe();
    const sarif = tempDir();
    assert.equal(tool('gitleaks').run(exe, null), true);
    assert.equal(tool('gitleaks').run(exe, sarif), true);
    const [plain, asSarif] = calls();
    assert.deepEqual(plain, ['git', '--redact', '--no-banner', '--exit-code', '1', ROOT]);
    assert.deepEqual(asSarif, [
        'git', '--redact', '--no-banner', '--exit-code', '1',
        '--report-format', 'sarif', '--report-path', join(sarif, 'gitleaks.sarif'), ROOT
    ]);
});
