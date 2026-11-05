import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const TOOLS = join(dirname(fileURLToPath(import.meta.url)), '..');

// Node's coverage only reports a file some test has loaded. Loading every
// tool here means a tool nothing else tests counts as uncovered instead of
// vanishing from the report.
test('every tool module loads, so coverage counts each one', async () => {
    const modules = readdirSync(TOOLS).filter((name) => name.endsWith('.mjs'));
    assert.ok(modules.includes('package.mjs'));
    for (const name of modules) {
        await import(pathToFileURL(join(TOOLS, name)).href);
    }
});
