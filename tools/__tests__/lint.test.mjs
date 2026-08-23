import { test } from 'node:test';
import assert from 'node:assert/strict';
import { lintSource, lintFiles, lintCalls } from '../lint.mjs';

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

test('flags division with variable divisor without forcing result', () => {
    assert.match(messages('A() {\n    x = a / b;\n}\n')[0], /RoundDown/);
});

test('flags division without spaces around operator', () => {
    assert.match(messages('A() {\n    total/7;\n}\n')[0], /RoundDown/);
});

test('allows division with RoundUp', () => {
    assert.deepEqual(lintSource('a.mss', 'A() {\n    x = RoundUp(a / 7);\n}\n'), []);
});

test('allows division with Round', () => {
    assert.deepEqual(lintSource('a.mss', 'A() {\n    x = Round(a / b);\n}\n'), []);
});

test('does not flag division in comments', () => {
    assert.deepEqual(lintSource('a.mss', 'A() {\n    x = 1; // This is 1/2 comment\n    y = 2;\n}\n'), []);
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

test('flags mixed and/or where not all connectives are parenthesised', () => {
    assert.match(messages('A() {\n    if ((a = 1) and (b = 2) or z = 3 and w = 4) {\n    }\n}\n')[0], /parenthes/);
});

test('allows multiple and/or when all are parenthesised', () => {
    assert.deepEqual(lintSource('a.mss', 'A() {\n    if ((a = 1) and (b = 2) or (z = 3) and (w = 4)) {\n    }\n}\n'), []);
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

test('skips manifest paths that do not exist on disk', () => {
    const mockFs = {
        'exists.mss': true,
        'missing.mss': false
    };
    const mockRead = (path) => mockFs[path] ? 'A() {\n    x = 1;\n}\n' : null;
    const results = lintFiles(['exists.mss', 'missing.mss'], mockRead);
    // The real test is that it doesn't throw or report the missing file as a finding
    assert.equal(results.findings.length, 0);
    assert.equal(results.skipped.length, 1);
    assert.equal(results.skipped[0], 'missing.mss');
});

test('reports linted files and skipped files accurately', () => {
    const mockFs = {
        'a.mss': true,
        'b.mss': true,
        'c.mss': false
    };
    const mockRead = (path) => mockFs[path] ? 'A() {\n    x += 1;\n}\n' : null;
    const results = lintFiles(['a.mss', 'b.mss', 'c.mss'], mockRead);
    // Two files linted (both have +=), one skipped
    assert.equal(results.findings.length, 2);
    assert.equal(results.skipped.length, 1);
});

test('flags .Length applied to a subscripted expression', () => {
    const findings = lintSource('x.mss', "A() {\n    n = built.treble[0].Length;\n    m = 1;\n}\n");
    assert.equal(findings.length, 1);
    assert.match(findings[0].message, /\.Length to a subscripted expression/);
});

test('flags a chained subscript', () => {
    const findings = lintSource('x.mss', "A() {\n    p = built.treble[0][0].pitch;\n    m = 1;\n}\n");
    assert.equal(findings.length, 1);
    assert.match(findings[0].message, /chains two subscripts/);
});

test('allows .Length on a plain name and a property on one subscript', () => {
    const source = "A() {\n    n = treble.Length;\n    p = stack[0].pitch;\n"
        + "    columns[index[key]].notes.Push(entry);\n    m = 1;\n}\n";
    assert.deepEqual(lintSource('x.mss', source), []);
});

test('does not flag the subscript forms when they appear inside a string', () => {
    const source = "A() {\n    trace('  ' & label & '[' & i & '].Length = ' & column.Length);\n    m = 1;\n}\n";
    assert.deepEqual(lintSource('x.mss', source), []);
});

test('flags a double quote inside a comment, as build.mjs does', () => {
    const findings = lintSource('x.mss', 'A() {\n    // a " quote in a comment\n    x = 1;\n}\n');
    assert.equal(findings.length, 1);
    assert.match(findings[0].message, /double quote/);
});

test('lintCalls accepts a plug-in whose calls are all defined or built in', () => {
    const sources = [
        ['a.mss', 'Run() {\n    x = Helper(CreateSparseArray());\n    trace(x);\n}\n'],
        ['b.mss', 'Helper(list) {\n    return list.Length;\n}\n']
    ];
    assert.deepEqual(lintCalls(sources), []);
});

test('lintCalls flags a call into a module left out of the manifest entry', () => {
    const sources = [['a.mss', 'Run() {\n    x = Helper(1);\n}\n']];
    const findings = lintCalls(sources);
    assert.equal(findings.length, 1);
    assert.equal(findings[0].line, 2);
    assert.match(findings[0].message, /calls Helper, which no source in this plug-in defines/);
});

test('lintCalls ignores dotted calls, which the host resolves', () => {
    const sources = [['a.mss', 'Run() {\n    s = Sibelius.ActiveScore;\n'
        + '    n = s.NthStaff(1);\n    utils.DeleteStaff(s, 1, False);\n}\n']];
    assert.deepEqual(lintCalls(sources), []);
});

test('lintCalls ignores control keywords and text inside strings and comments', () => {
    const sources = [['a.mss', 'Run() {\n    if (x = 1) {\n        while (y) {\n'
        + "            trace('Missing(1) here');\n            // Absent(2) too\n"
        + '        }\n    }\n    for i = 0 to 3 {\n    }\n}\n']];
    assert.deepEqual(lintCalls(sources), []);
});

test('the arithmetic rule sees an expression that opens right after a bracket', () => {
    assert.match(messages('A() {\n    x = Foo(a + b * c);\n}\n')[0], /no operator precedence/);
});

test('the arithmetic rule still accepts a fully bracketed expression', () => {
    assert.deepEqual(lintSource('a.mss', 'A() {\n    x = (a + b) * c;\n}\n'), []);
});

test('the division rule sees a division that is not followed by ; or )', () => {
    assert.match(messages('A() {\n    x = a / b + c;\n}\n').join(' '), /divides without forcing/);
    assert.match(messages('A() {\n    x = Method(a / b, c);\n}\n').join(' '), /divides without forcing/);
});
