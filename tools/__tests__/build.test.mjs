import { test } from 'node:test';
import assert from 'node:assert/strict';
import { parseMethods, buildPlugin, buildEntry } from '../build.mjs';

test('parseMethods reads a single method', () => {
    const src = 'Foo(a, b) {\n    return a;\n}\n';
    assert.deepEqual(parseMethods(src), [
        { name: 'Foo', params: 'a, b', body: '\n    return a;\n' }
    ]);
});

test('parseMethods reads several methods and nested braces', () => {
    const src = 'A() {\n    if (x = 1) {\n        y = 2;\n    }\n}\nB(n) {\n    return n;\n}\n';
    const got = parseMethods(src);
    assert.equal(got.length, 2);
    assert.equal(got[0].name, 'A');
    assert.equal(got[1].name, 'B');
    assert.equal(got[1].params, 'n');
});

test('buildPlugin emits plg syntax with data variables', () => {
    const entry = {
        output: 'X.plg',
        sources: ['src/A.mss'],
        data: { _PluginMenuName: 'Test Plugin' }
    };
    const files = { 'src/A.mss': 'Run() {\n    trace(\'hi\');\n}\n' };
    const out = buildPlugin(entry, (p) => files[p]);
    assert.equal(out, '{\n\tRun "() {\n    trace(\'hi\');\n}"\n\t_PluginMenuName "Test Plugin"\n}\n');
});

test('buildPlugin preserves backslash escapes in bodies', () => {
    const entry = { output: 'X.plg', sources: ['a.mss'], data: {} };
    const files = { 'a.mss': 'Run() {\n    trace(\'a\\nb\');\n}\n' };
    assert.ok(buildPlugin(entry, (p) => files[p]).includes("'a\\nb'"));
});

test('buildPlugin rejects a double quote in a body', () => {
    const entry = { output: 'X.plg', sources: ['a.mss'], data: {} };
    const files = { 'a.mss': 'Run() {\n    trace("x");\n}\n' };
    assert.throws(() => buildPlugin(entry, (p) => files[p]), /double quote/);
});

test('buildPlugin rejects duplicate method names across files', () => {
    const entry = { output: 'X.plg', sources: ['a.mss', 'b.mss'], data: {} };
    const files = { 'a.mss': 'Same() {\n}\n', 'b.mss': 'Same() {\n}\n' };
    assert.throws(() => buildPlugin(entry, (p) => files[p]), /Same/);
});

test('buildPlugin emits a raw file byte-for-byte between methods and data', () => {
    const entry = {
        output: 'X.plg',
        sources: ['src/A.mss'],
        raw: ['src/Fixture.raw'],
        data: { _PluginMenuName: 'Test Plugin' }
    };
    // A synthetic stand-in for a captured dialog block: deliberately carries a
    // backslash and a tab so a passthrough that quoted or escaped it would be
    // caught by this assertion.
    const rawContent = '_FixtureDialog "block\twith\\backslash\nand a newline"';
    const files = {
        'src/A.mss': 'Run() {\n    trace(\'hi\');\n}\n',
        'src/Fixture.raw': rawContent
    };
    const out = buildPlugin(entry, (p) => files[p]);
    assert.ok(out.includes(rawContent), 'raw content must appear unchanged');

    const methodIndex = out.indexOf('Run "');
    const rawIndex = out.indexOf(rawContent);
    const dataIndex = out.indexOf('_PluginMenuName');
    assert.ok(methodIndex < rawIndex, 'raw content must come after methods');
    assert.ok(rawIndex < dataIndex, 'raw content must come before data variables');
});

test('buildPlugin reports a missing raw file', () => {
    const entry = { output: 'X.plg', sources: ['a.mss'], raw: ['b.raw'], data: {} };
    const files = { 'a.mss': 'Run() {\n}\n' };
    assert.throws(
        () => buildPlugin(entry, (p) => files[p] ?? null),
        /b\.raw/
    );
});

test('buildEntry treats a missing raw file the same as a missing source', () => {
    const entry = { output: 'X.plg', sources: ['a.mss'], raw: ['b.raw'] };
    const files = { 'a.mss': 'Run() {\n}\n' };
    const io = {
        exists: (p) => p in files,
        read: (p) => files[p] ?? null,
        write: () => { throw new Error('must not write a plugin with a missing raw file'); },
        remove: () => {}
    };
    const result = buildEntry(entry, io);
    assert.equal(result.status, 'skipped');
    assert.deepEqual(result.missing, ['b.raw']);
});

test('buildPlugin rejects a double quote in a data variable', () => {
    const entry = { output: 'X.plg', sources: ['a.mss'], data: { _Key: 'val"ue' } };
    const files = { 'a.mss': 'Run() {\n}\n' };
    assert.throws(() => buildPlugin(entry, (p) => files[p]), /double quote/);
});

test('buildPlugin reports which source is missing', () => {
    const entry = { output: 'X.plg', sources: ['a.mss', 'b.mss'] };
    const files = { 'a.mss': 'Run() {\n}\n' };
    assert.throws(
        () => buildPlugin(entry, (p) => files[p] ?? null),
        /b\.mss/
    );
});

test('buildEntry removes a stale output when its plugin is skipped', () => {
    const entry = { output: 'X.plg', sources: ['a.mss', 'b.mss'] };
    const files = { 'a.mss': 'Run() {\n}\n', 'build/X.plg': '{\n}\n' };
    const removed = [];
    const io = {
        exists: (p) => p in files,
        read: (p) => files[p] ?? null,
        write: () => { throw new Error('must not write a plugin with a missing source'); },
        remove: (p) => removed.push(p)
    };
    const result = buildEntry(entry, io);
    assert.equal(result.status, 'skipped');
    assert.deepEqual(result.missing, ['b.mss']);
    assert.deepEqual(removed, ['build/X.plg']);
});

test('buildEntry does not attempt removal when there is no stale output', () => {
    const entry = { output: 'X.plg', sources: ['a.mss', 'b.mss'] };
    const files = { 'a.mss': 'Run() {\n}\n' };
    const removed = [];
    const io = {
        exists: (p) => p in files,
        read: (p) => files[p] ?? null,
        write: () => { throw new Error('must not write a plugin with a missing source'); },
        remove: (p) => removed.push(p)
    };
    const result = buildEntry(entry, io);
    assert.equal(result.status, 'skipped');
    assert.deepEqual(removed, []);
});

test('buildEntry builds and writes when every source is present', () => {
    const entry = { output: 'X.plg', sources: ['a.mss'], data: {} };
    const files = { 'a.mss': 'Run() {\n}\n' };
    const written = [];
    const io = {
        exists: (p) => p in files,
        read: (p) => files[p] ?? null,
        write: (p, text) => written.push([p, text]),
        remove: () => { throw new Error('must not remove anything when nothing is stale'); }
    };
    const result = buildEntry(entry, io);
    assert.equal(result.status, 'built');
    assert.equal(written.length, 1);
    assert.equal(written[0][0], 'build/X.plg');
});

test('buildEntry refuses an output name that escapes build/', () => {
    const io = {
        exists: () => false,
        read: () => null,
        write: () => assert.fail('must not write'),
        remove: () => assert.fail('must not remove')
    };
    const entry = { output: '../../etc/passwd', sources: ['a.mss'] };
    assert.throws(() => buildEntry(entry, io), /must be a bare filename/);
});

// A combo box takes its contents from a Data variable holding a list of
// strings, and the .plg spells that as a braced block rather than a quoted
// value. The plugin fills these at run time, so what the build has to emit is
// the empty block that makes the variable exist as a list.
test('buildPlugin emits an array data variable as a braced block', () => {
    const entry = { output: 'X.plg', sources: ['a.mss'], data: { _Items: ['one', 'two'] } };
    const files = { 'a.mss': 'Run() {\n}\n' };
    const out = buildPlugin(entry, (p) => files[p]);
    assert.ok(out.includes('\t_Items\n\t{\n\t\t"one"\n\t\t"two"\n\t}\n'), out);
});

test('buildPlugin emits an empty array data variable as an empty block', () => {
    const entry = { output: 'X.plg', sources: ['a.mss'], data: { _Items: [] } };
    const files = { 'a.mss': 'Run() {\n}\n' };
    const out = buildPlugin(entry, (p) => files[p]);
    assert.ok(out.includes('\t_Items\n\t{\n\t}\n'), out);
});

test('buildPlugin rejects a double quote in an array data variable', () => {
    const entry = { output: 'X.plg', sources: ['a.mss'], data: { _Items: ['va"lue'] } };
    const files = { 'a.mss': 'Run() {\n}\n' };
    assert.throws(() => buildPlugin(entry, (p) => files[p]), /double quote/);
});
