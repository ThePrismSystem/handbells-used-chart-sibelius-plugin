#!/usr/bin/env node
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

// A method is `Name(params) {` at column zero through its matching brace.
// Anchoring at column zero is what separates a method header from an `if`
// or `for` inside one, without needing to parse the language.
export function parseMethods(source) {
    const methods = [];
    const header = /^([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)\s*\{/gm;
    let match;
    while ((match = header.exec(source)) !== null) {
        const start = match.index + match[0].length;
        let depth = 1;
        let i = start;
        while (i < source.length && depth > 0) {
            if (source[i] === '{') depth = depth + 1;
            else if (source[i] === '}') depth = depth - 1;
            i = i + 1;
        }
        if (depth !== 0) {
            throw new Error(`Unbalanced braces in method ${match[1]}`);
        }
        methods.push({
            name: match[1],
            params: match[2].trim(),
            body: source.slice(start, i - 1)
        });
        header.lastIndex = i;
    }
    return methods;
}

export function buildPlugin(entry, read) {
    const exclude = new Set(entry.exclude || []);
    const seen = new Map();
    const lines = ['{'];

    for (const path of entry.sources) {
        if (exclude.has(path)) continue;
        const source = read(path);
        if (source === null) {
            throw new Error(`Missing source ${path}`);
        }
        for (const method of parseMethods(source)) {
            if (method.body.includes('"')) {
                throw new Error(
                    `${path}: method ${method.name} contains a double quote, ` +
                    `which would terminate the .plg string. Use single quotes.`
                );
            }
            if (seen.has(method.name)) {
                throw new Error(
                    `Duplicate method ${method.name} in ${path}, ` +
                    `already defined in ${seen.get(method.name)}. ` +
                    `ManuScript has one flat namespace.`
                );
            }
            seen.set(method.name, path);
            lines.push(`\t${method.name} "(${method.params}) {${method.body}}"`);
        }
    }

    for (const [name, value] of Object.entries(entry.data || {})) {
        if (String(value).includes('"')) {
            throw new Error(`Data variable ${name} contains a double quote`);
        }
        lines.push(`\t${name} "${value}"`);
    }

    lines.push('}');
    return lines.join('\n') + '\n';
}

function main() {
    const manifest = JSON.parse(readFileSync(join(ROOT, 'tools/plugins.json'), 'utf8'));
    mkdirSync(join(ROOT, 'build'), { recursive: true });

    for (const entry of manifest.plugins) {
        const missing = entry.sources.filter((p) => !existsSync(join(ROOT, p)));
        if (missing.length > 0) {
            // A later task writes these. Say so loudly: a silent skip here would
            // let a stale .plg from an earlier build reach Sibelius unnoticed.
            console.log(`skipped build/${entry.output} (not yet written: ${missing.join(', ')})`);
            continue;
        }
        const text = buildPlugin(entry, (p) => readFileSync(join(ROOT, p), 'utf8'));
        writeFileSync(join(ROOT, 'build', entry.output), text, 'utf8');
        console.log(`built build/${entry.output}`);
    }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main();
