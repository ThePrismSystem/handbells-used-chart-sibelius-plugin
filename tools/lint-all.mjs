#!/usr/bin/env node
// Runs the project's linters and security scanners over the files git tracks.
//
//   node tools/lint-all.mjs                         every tool that is installed; a missing one is skipped
//   node tools/lint-all.mjs --only eslint,zizmor    just those
//   node tools/lint-all.mjs --strict                a missing tool fails the run (CI uses this)
//   node tools/lint-all.mjs --sarif DIR             zizmor and gitleaks also write SARIF files to DIR
//
// Only files in git's index are checked, so a new file is left out until it
// is added, and ignored files are always left out.
import { mkdirSync, statSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { delimiter, dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

export function tracked(patterns, cwd = ROOT) {
    const out = spawnSync('git', ['ls-files', '-z', '--', ...patterns], { cwd, encoding: 'utf8' });
    if (out.status !== 0) throw new Error(`git ls-files failed: ${out.stderr}`);
    return out.stdout.split('\0').filter(Boolean).sort();
}

// The project's node_modules/.bin first, where npm puts ESLint, then the PATH.
export function findExe(name, dirs = [join(ROOT, 'node_modules', '.bin'), ...(process.env.PATH || '').split(delimiter)]) {
    const suffixes = process.platform === 'win32' ? ['', ...(process.env.PATHEXT || '.EXE;.CMD').split(';')] : [''];
    for (const dir of dirs) {
        for (const suffix of suffixes) {
            const candidate = join(dir, name + suffix);
            try {
                if (statSync(candidate).isFile()) return candidate;
            } catch {
                // not here
            }
        }
    }
    return null;
}

// A .cmd shim (ESLint on Windows) only runs through a shell.
export function spawnOptions(exe, options = {}) {
    return { cwd: ROOT, stdio: 'inherit', shell: /\.cmd$/i.test(exe), ...options };
}

function run(exe, args, options = {}) {
    return spawnSync(exe, args, spawnOptions(exe, options));
}

function manuscript(exe) {
    return run(exe, [join(ROOT, 'tools', 'lint.mjs')]).status === 0;
}

function eslint(exe) {
    const files = tracked(['*.mjs']);
    return run(exe, ['--max-warnings', '0', '--no-warn-ignored', ...files]).status === 0;
}

function zizmor(exe, sarifDir) {
    const files = tracked(['.github/workflows/*.yml']);
    const clean = run(exe, files).status === 0;
    if (sarifDir) {
        const sarif = run(exe, ['--format', 'sarif', ...files], { stdio: ['ignore', 'pipe', 'inherit'], encoding: 'utf8' });
        writeFileSync(join(sarifDir, 'zizmor.sarif'), sarif.stdout);
    }
    return clean;
}

function gitleaks(exe, sarifDir) {
    const args = ['git', '--redact', '--no-banner', '--exit-code', '1'];
    if (sarifDir) args.push('--report-format', 'sarif', '--report-path', join(sarifDir, 'gitleaks.sarif'));
    return run(exe, [...args, ROOT]).status === 0;
}

export const TOOLS = [
    { name: 'manuscript', find: () => process.execPath, install: '', run: manuscript },
    { name: 'eslint', find: () => findExe('eslint'), install: 'Run npm ci.', run: eslint },
    { name: 'zizmor', find: () => findExe('zizmor'), install: 'pipx install zizmor (lint.yml has the version).', run: zizmor },
    {
        name: 'gitleaks',
        find: () => findExe('gitleaks'),
        install: 'Get it from https://github.com/gitleaks/gitleaks/releases (lint.yml has the version).',
        run: gitleaks
    }
];

function runTool(tool, strict, sarifDir) {
    const exe = tool.find();
    if (!exe) {
        const status = strict ? 'FAIL' : 'SKIP';
        console.log(`${status}  ${tool.name}: ${tool.name} not found. ${tool.install}`);
        return status;
    }
    const status = tool.run(exe, sarifDir) ? 'PASS' : 'FAIL';
    console.log(`${status}  ${tool.name}`);
    return status;
}

export function main(argv, tools = TOOLS) {
    let strict = false;
    let sarifDir = null;
    let only = null;
    for (let i = 0; i < argv.length; i++) {
        if (argv[i] === '--strict') strict = true;
        else if (argv[i] === '--sarif') sarifDir = resolve(argv[++i]);
        else if (argv[i] === '--only') only = argv[++i].split(',');
        else {
            console.log(`unknown argument: ${argv[i]}`);
            return 2;
        }
    }
    if (only) {
        const unknown = only.filter((name) => !tools.some((tool) => tool.name === name));
        if (unknown.length > 0) {
            console.log(`unknown tool: ${unknown.join(', ')}`);
            return 2;
        }
    }
    if (sarifDir) mkdirSync(sarifDir, { recursive: true });
    const chosen = only ? tools.filter((tool) => only.includes(tool.name)) : tools;
    const results = chosen.map((tool) => runTool(tool, strict, sarifDir));
    if (results.includes('FAIL')) {
        console.log('SOME FAILED');
        return 1;
    }
    const skipped = results.filter((result) => result === 'SKIP').length;
    console.log(`ALL PASS${skipped ? ` (${skipped} skipped)` : ''}`);
    return 0;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) process.exitCode = main(process.argv.slice(2));
