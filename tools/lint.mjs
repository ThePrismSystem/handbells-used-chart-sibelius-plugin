#!/usr/bin/env node
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseMethods } from './build.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

const RULES = [
    // Checked against the RAW line, comments included: a .plg wraps the WHOLE
    // method body in double quotes, so a quote inside a // comment breaks the
    // file exactly as one in code does. build.mjs rejects it either way; lint
    // has to agree, or lint passes and the build fails for a reason lint
    // just told you was fine.
    [/"/, 'contains a double quote; a .plg stores method bodies in double quotes, so use single quotes, in comments as well as code', null, true],
    [/\+=|-=|\*=|\/=/, 'uses += or similar; ManuScript has no compound assignment, write x = x + 1'],
    [/\+\+|--/, 'uses ++ or --; ManuScript has neither'],
    [/==/, 'uses ==; ManuScript compares with a single ='],
    // Left-to-right evaluation means 2+3*4 is 20. Any line mixing an additive
    // and a multiplicative operator without parentheses is a silent wrong answer.
    // An already-bracketed `(a + b) * c` cannot match, because the character
    // after the additive operand is `)` rather than `*` — so this needs no
    // leading exclusion, and having one blinded it to `Foo(a + b * c)`.
    [/\b[\w.]+\s*[+\-]\s*[\w.]+\s*[*/%]/, 'mixes + or - with * / or % without parentheses; ManuScript has no operator precedence'],
    // The guide says / now yields floats; Zawalich's field notes say integer
    // operands still truncate. Neither can be relied on, so force the result.
    // Skipped when the line already forces it — otherwise this rule fires on
    // `RoundDown(a / 7)`, the very idiom it exists to recommend.
    [null, null, divisionUnforced],
    // H1..H9. Each is a documented way to get a wrong answer, not a style rule.
    [null, null, andOrUnparenthesised],
    [/for\s+each\s+Note\s+\w+\s+in\b/, 'uses `for each Note n in ...`; inside a NoteRest this must be `for each n in nr`'],
    [/\/\*|\*\//, 'uses a block comment; these corrupt the line numbers in ManuScript error reports'],
    [/\.Push\s*\(\s*(True|False)\s*\)|\[\s*[^\]]+\s*\]\s*=\s*(True|False)\s*;/, 'stores a Boolean in an array; store 1 or 0 instead'],
    // Sibelius rejects both of these with a bare 'Parse error near \'. Found
    // the hard way: the plugin failed to load at the first `expr[i].Length` in
    // the file. `name.Length` and `name[i].Property` are fine and used
    // throughout the guide; it is applying .Length or a further subscript to an
    // already-subscripted expression that the parser will not take. Bind the
    // subscripted value to a local first.
    [null, 'applies .Length to a subscripted expression; assign it to a variable first, as Sibelius will not parse this', subscriptThenLength],
    [null, 'chains two subscripts; assign the first lookup to a variable first, as Sibelius will not parse this', chainedSubscript]
];

// `and`/`or` bind left to right like everything else, so an unparenthesised
// `a = 1 and b = 2` does not mean what it looks like. Accept the line only when
// both sides of every connective are already bracketed.
function andOrUnparenthesised(code) {
    if (!/\b(and|or)\b/.test(code)) return false;
    // Replace all properly bracketed connectives; if any remain, flag it
    let temp = code;
    while (temp.match(/\)\s*\b(and|or)\b\s*\(/)) {
        temp = temp.replace(/\)\s*\b(and|or)\b\s*\(/, '___');
    }
    return /\b(and|or)\b/.test(temp);
}

// Both of these run on the string-blanked copy: a trace message containing the
// literal text '].Length' is not a use of the construct.
function subscriptThenLength(code) {
    return /\]\s*\.Length\b/.test(code);
}

function chainedSubscript(code) {
    return /\]\s*\[/.test(code);
}

// A division is fine once the line commits to an integer or a float result.
// The exemption is line-scoped, so one forced division on a line exempts every
// other division on it. Narrowing that needs expression parsing; until then,
// keep one division per line.
function divisionUnforced(code) {
    if (!/\/\s*[\w.(]/.test(code)) return false;
    return !/\bRound(Down|Up)?\s*\(|\*\s*1\.0/.test(code);
}

// ManuScript resolves calls at run time against one flat namespace per .plg,
// so a module left out of a plugins.json entry still builds and still loads —
// it fails at the first call into the missing file, in front of the user. The
// allow-list is deliberately only what this project uses: a genuinely new
// built-in should fail this check once and be added on purpose.
const BUILTINS = new Set([
    'AddToPluginsMenu', 'CreateArray', 'CreateDictionary', 'CreateHash',
    'CreateSparseArray', 'EnableStringSafety', 'IsObject', 'Length',
    'LowerCase', 'UpperCase', 'RoundDown', 'RoundUp', 'Substring',
    'SetInterpreterOption', 'StrToNum', 'CharAt', 'Chr', 'Asc', 'not', 'trace'
]);

const KEYWORDS = new Set(['if', 'while', 'for', 'switch', 'case', 'return', 'and', 'or']);

// `sources` is [path, text] pairs — one manifest entry's whole source list,
// because that is the scope a .plg's namespace actually has.
export function lintCalls(sources) {
    const defined = new Set();
    for (const [, text] of sources) {
        for (const method of parseMethods(text)) defined.add(method.name);
    }

    const findings = [];
    for (const [path, text] of sources) {
        text.split('\n').forEach((line, index) => {
            const code = line.replace(/\/\/.*$/, '').replace(/'[^']*'/g, "''");
            for (const match of code.matchAll(/(\.?)\b([A-Za-z_][A-Za-z0-9_]*)\s*\(/g)) {
                // A dotted call is a method on an object or on Sibelius/utils,
                // resolved by the host, not by this plug-in's namespace.
                if (match[1] === '.') continue;
                const name = match[2];
                if (defined.has(name) || BUILTINS.has(name) || KEYWORDS.has(name)) continue;
                findings.push({
                    path,
                    line: index + 1,
                    message: `${path}:${index + 1} calls ${name}, which no source in this plug-in defines`
                });
            }
        });
    }
    return findings;
}

export function lintSource(path, source) {
    const findings = [];
    const lines = source.split('\n');
    const report = (index, message) =>
        findings.push({ path, line: index + 1, message: `${path}:${index + 1} ${message}` });

    lines.forEach((text, index) => {
        const code = text.replace(/\/\/.*$/, '');
        // Predicate rules run against a copy with string literals blanked, so a
        // message like 'bells and chimes' is not read as a boolean connective.
        // The plain-pattern rules still see the raw line, because the
        // double-quote rule is specifically about what is inside strings.
        const bare = code.replace(/'[^']*'/g, "''");
        for (const [pattern, message, predicate, onRaw] of RULES) {
            if (predicate) {
                if (predicate(bare)) {
                    // Older predicate rules carry no message of their own.
                    if (message) {
                        report(index, message);
                    } else {
                        report(index, predicate === divisionUnforced
                            ? 'divides without forcing the result; use RoundDown(a / b) for an integer or (a * 1.0) / b for a float'
                            : 'mixes and/or without parenthesising both sides; ManuScript has no operator precedence');
                    }
                }
            } else if (pattern.test(onRaw ? text : code)) {
                report(index, message);
            }
        }
    });

    // Dynamic variables are indirection over ordinary variables, and ordinary
    // variables are method-local: only Data variables and user properties are
    // global. A method that reads `@name` without having written one in the
    // same body is reaching for a variable that cannot exist, and Sibelius
    // answers by opening the plug-in editor mid-run and carrying on in an
    // undefined state. Found by splitting a collect phase from an apply phase.
    for (const method of parseMethods(source)) {
        const body = method.body.replace(/\/\/.*$/gm, '').replace(/'[^']*'/g, "''");
        const writes = /@\w+\s*=(?!=)/.test(body);
        const reads = [...body.matchAll(/@(\w+)/g)]
            .filter((m) => !/^\s*=(?!=)/.test(body.slice(m.index + m[0].length)));
        if (reads.length > 0 && !writes) {
            report(0, `method ${method.name} reads a dynamic variable it never assigns; `
                + `these are method-local, so pass the values as a parameter instead`);
        }
    }

    // H8: a `//` comment on a method's closing line is a syntax error.
    for (const method of parseMethods(source)) {
        const body = method.body.replace(/\s+$/, '');
        const last = body.split('\n').pop() || '';
        if (last.includes('//')) {
            report(0, `method ${method.name} ends with a // comment on its last line, which ManuScript rejects`);
        }
    }

    return findings;
}

export function lintFiles(paths, read) {
    const findings = [];
    const skipped = [];

    for (const path of paths) {
        const source = read(path);
        if (source === null) {
            skipped.push(path);
            continue;
        }
        findings.push(...lintSource(path, source));
    }

    return { findings, skipped };
}

function main() {
    const manifest = JSON.parse(readFileSync(join(ROOT, 'tools/plugins.json'), 'utf8'));
    const paths = [...new Set(manifest.plugins.flatMap((p) => p.sources))];

    const read = (path) => {
        const fullPath = join(ROOT, path);
        if (!existsSync(fullPath)) return null;
        return readFileSync(fullPath, 'utf8');
    };

    const { findings, skipped } = lintFiles(paths, read);
    const linted = paths.length - skipped.length;

    // Per entry, not per file: the namespace a call resolves against is the
    // whole .plg. An entry with an unwritten source cannot be judged yet.
    for (const entry of manifest.plugins) {
        const sources = entry.sources.map((p) => [p, read(p)]);
        if (sources.some(([, text]) => text === null)) {
            console.log(`skipped call check for ${entry.output} (sources not yet written)`);
            continue;
        }
        findings.push(...lintCalls(sources));
    }

    for (const finding of findings) {
        console.error(finding.message);
    }

    for (const path of skipped) {
        console.log(`skipped (not yet written): ${path}`);
    }

    if (findings.length > 0) {
        console.error(`${findings.length} lint finding(s)`);
        process.exit(1);
    }

    console.log(`${linted} file(s) linted, ${skipped.length} skipped`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main();
