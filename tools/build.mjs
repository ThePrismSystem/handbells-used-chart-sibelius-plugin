#!/usr/bin/env node
import { readFileSync, writeFileSync, mkdirSync, existsSync, unlinkSync } from 'node:fs';
import { basename, dirname, join } from 'node:path';
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
    const seen = new Map();
    const lines = ['{'];

    for (const path of entry.sources) {
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

    // Raw entries are dropped in byte-for-byte: no quoting, no escaping. A
    // dialog captured out of Sibelius's own editor already carries its own
    // `Name "value"` shape, and re-quoting it would corrupt the very bytes
    // the capture step exists to preserve.
    for (const path of entry.raw || []) {
        const content = read(path);
        if (content === null) {
            throw new Error(`Missing source ${path}`);
        }
        lines.push(content);
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

// Decides one manifest entry's outcome and carries it out through the
// injected io, so a skip can never leave a stale .plg from an earlier build
// sitting where deploy.mjs would still pick it up.
export function buildEntry(entry, io) {
    // This function deletes files, so the output name has to stay a bare
    // filename. join('build', '../../x') escapes build/ entirely, and the
    // manifest being repo-controlled today is not a reason to let a later
    // edit to it reach outside.
    if (entry.output !== basename(entry.output)) {
        throw new Error(`Plugin output ${entry.output} must be a bare filename`);
    }
    const outputPath = join('build', entry.output);
    const required = [...entry.sources, ...(entry.raw || [])];
    const missing = required.filter((p) => !io.exists(p));

    if (missing.length > 0) {
        const removedStale = io.exists(outputPath);
        if (removedStale) io.remove(outputPath);
        return { status: 'skipped', outputPath, missing, removedStale };
    }

    const text = buildPlugin(entry, io.read);
    io.write(outputPath, text);
    return { status: 'built', outputPath };
}

function main() {
    const manifest = JSON.parse(readFileSync(join(ROOT, 'tools/plugins.json'), 'utf8'));
    mkdirSync(join(ROOT, 'build'), { recursive: true });

    const io = {
        exists: (p) => existsSync(join(ROOT, p)),
        read: (p) => (existsSync(join(ROOT, p)) ? readFileSync(join(ROOT, p), 'utf8') : null),
        write: (p, text) => writeFileSync(join(ROOT, p), text, 'utf8'),
        remove: (p) => unlinkSync(join(ROOT, p))
    };

    for (const entry of manifest.plugins) {
        const result = buildEntry(entry, io);
        if (result.status === 'skipped') {
            // A later task writes these sources. Say so loudly, and say just as
            // loudly when a stale .plg from an earlier build gets removed.
            // deploy.mjs copies whatever it finds in build/, so leaving one there
            // would let it reach Sibelius unnoticed.
            const staleNote = result.removedStale ? `; removed stale ${result.outputPath}` : '';
            console.log(`skipped ${result.outputPath} (not yet written: ${result.missing.join(', ')})${staleNote}`);
            continue;
        }
        console.log(`built ${result.outputPath}`);
    }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main();
