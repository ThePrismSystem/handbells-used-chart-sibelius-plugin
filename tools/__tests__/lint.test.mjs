import { test } from 'node:test';
import assert from 'node:assert/strict';
import { lintSource } from '../lint.mjs';

const messages = (src) => lintSource('a.mss', src).map((f) => f.message);

test('accepts clean source', () => {
    assert.deepEqual(lintSource('a.mss', 'A() {\n    x = x + 1;\n}\n'), []);
});

test('rejects double-quoted strings', () => {
    assert.match(messages('A() {\n    trace("x");\n}\n')[0], /double quote/);
});

test('rejects += and ++', () => {
    assert.match(messages('A() {\n    x += 1;\n}\n')[0], /\+=/);
    assert.match(messages('A() {\n    x++;\n}\n')[0], /\+\+/);
});

test('rejects == ', () => {
    assert.match(messages('A() {\n    if (x == 1) {\n    }\n}\n')[0], /==/);
});

test('flags unparenthesised mixed arithmetic', () => {
    assert.match(messages('A() {\n    x = 2 + 3 * 4;\n}\n')[0], /precedence/);
});

test('allows mixed arithmetic when parenthesised', () => {
    assert.deepEqual(lintSource('a.mss', 'A() {\n    x = 2 + (3 * 4);\n}\n'), []);
});

test('flags integer division without forcing the result', () => {
    assert.match(messages('A() {\n    x = a / 7;\n}\n')[0], /RoundDown/);
});

test('allows division whose result is already forced', () => {
    assert.deepEqual(lintSource('a.mss', 'A() {\n    x = RoundDown(a / 7);\n}\n'), []);
    assert.deepEqual(lintSource('a.mss', 'A() {\n    x = (a * 1.0) / 7;\n}\n'), []);
});

test('does not read a word inside a string literal as a connective', () => {
    assert.deepEqual(lintSource('a.mss', "A() {\n    x = 'bells and chimes';\n}\n"), []);
});

test('reports the line number', () => {
    assert.equal(lintSource('a.mss', 'A() {\n    x = 1;\n    y += 2;\n}\n')[0].line, 3);
});

// Hazard rules. Each of these is a documented way to get a wrong answer.

test('flags unparenthesised and/or', () => {
    assert.match(messages('A() {\n    if (x = 1 and y = 2) {\n    }\n}\n')[0], /parenthes/);
    assert.match(messages('A() {\n    if (x = 1 or y = 2) {\n    }\n}\n')[0], /parenthes/);
});

test('allows parenthesised and/or', () => {
    assert.deepEqual(lintSource('a.mss', 'A() {\n    if ((x = 1) and (y = 2)) {\n    }\n}\n'), []);
});

test('flags typed Note iteration inside a NoteRest', () => {
    assert.match(messages('A() {\n    for each Note n in nr {\n    }\n}\n')[0], /for each n in/);
});

test('flags block comments', () => {
    assert.match(messages('A() {\n    /* nope */\n}\n')[0], /block comment/);
});

test('flags a trailing comment on the last line of a method', () => {
    assert.match(messages('A() {\n    x = 1; // boom\n}\n')[0], /last line/);
});

test('allows a comment that is not on the last line', () => {
    assert.deepEqual(lintSource('a.mss', 'A() {\n    x = 1; // fine\n    y = 2;\n}\n'), []);
});

test('flags True or False stored into a sparse array', () => {
    assert.match(messages('A() {\n    arr.Push(True);\n}\n')[0], /Boolean/);
});

test('skips manifest paths that do not exist on disk', async (t) => {
    const { execSync } = await import('node:child_process');
    const output = execSync('npm run lint 2>&1', { encoding: 'utf8', cwd: process.cwd() });
    assert.match(output, /skipped \(not yet written\):/);
    assert.match(output, /lint clean/);
});
