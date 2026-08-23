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

test('buildPlugin honours exclude', () => {
    const entry = {
        output: 'X.plg',
        sources: ['a.mss', 'b.mss'],
        exclude: ['b.mss'],
        data: {}
    };
    const files = { 'a.mss': 'A() {\n}\n', 'b.mss': 'B() {\n}\n' };
    const out = buildPlugin(entry, (p) => files[p]);
    assert.ok(out.includes('A "'));
    assert.ok(!out.includes('B "'));
});

test('buildPlugin rejects duplicate method names across files', () => {
    const entry = { output: 'X.plg', sources: ['a.mss', 'b.mss'], data: {} };
    const files = { 'a.mss': 'Same() {\n}\n', 'b.mss': 'Same() {\n}\n' };
    assert.throws(() => buildPlugin(entry, (p) => files[p]), /Same/);
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
