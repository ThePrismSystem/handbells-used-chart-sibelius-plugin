#!/usr/bin/env node
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseMethods } from './build.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

const RULES = [
    [/"/, 'contains a double quote; a .plg stores method bodies in double quotes, so use single quotes'],
    [/\+=|-=|\*=|\/=/, 'uses += or similar; ManuScript has no compound assignment, write x = x + 1'],
    [/\+\+|--/, 'uses ++ or --; ManuScript has neither'],
    [/==/, 'uses ==; ManuScript compares with a single ='],
    // Left-to-right evaluation means 2+3*4 is 20. Any line mixing an additive
    // and a multiplicative operator without parentheses is a silent wrong answer.
    [/[^(]\b[\w.]+\s*[+\-]\s*[\w.]+\s*[*/%]/, 'mixes + or - with * / or % without parentheses; ManuScript has no operator precedence'],
    // The guide says / now yields floats; Zawalich's field notes say integer
    // operands still truncate. Neither can be relied on, so force the result.
    // Skipped when the line already forces it — otherwise this rule fires on
    // `RoundDown(a / 7)`, the very idiom it exists to recommend.
    [/[^\w]\/\s*\d+\s*[;)]/, null, divisionUnforced],
    // H1..H9. Each is a documented way to get a wrong answer, not a style rule.
    [/\b(and|or)\b/, null, andOrUnparenthesised],
    [/for\s+each\s+Note\s+\w+\s+in\b/, 'uses `for each Note n in ...`; inside a NoteRest this must be `for each n in nr`'],
    [/\/\*|\*\//, 'uses a block comment; these corrupt the line numbers in ManuScript error reports'],
    [/\.Push\s*\(\s*(True|False)\s*\)|\[\s*[^\]]+\s*\]\s*=\s*(True|False)\s*;/, 'stores a Boolean in an array; store 1 or 0 instead']
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

// A division is fine once the line commits to an integer or a float result.
function divisionUnforced(code) {
    if (!/\/\s*[\w.]+\s*[;)]/.test(code)) return false;
    return !/\bRound(Down|Up)?\s*\(|\*\s*1\.0/.test(code);
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
        for (const [pattern, message, predicate] of RULES) {
            if (predicate) {
                if (predicate(bare)) {
                    report(index, predicate === divisionUnforced
                        ? 'divides without forcing the result; use RoundDown(a / b) for an integer or (a * 1.0) / b for a float'
                        : 'mixes and/or without parenthesising both sides; ManuScript has no operator precedence');
                }
            } else if (pattern.test(code)) {
                report(index, message);
            }
        }
    });

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
