#!/usr/bin/env node
import { readFileSync, mkdirSync, copyFileSync, rmSync, existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

// What a user installs, and what they need alongside it. The test plug-in is
// deliberately absent: it builds a real chart on the open score and removes it
// again, which is a development tool, not something to hand to a musician.
const PLUGIN = 'HandbellsUsedChart.plg';
const DOCS = ['README.md', 'LICENSE.md', 'CHANGELOG.md'];

function main() {
    const { version } = JSON.parse(readFileSync(join(ROOT, 'package.json'), 'utf8'));
    const built = join(ROOT, 'build', PLUGIN);
    if (!existsSync(built)) {
        throw new Error(`${PLUGIN} is not built. Run npm run build first.`);
    }

    const name = `handbells-used-chart-v${version}`;
    const dist = join(ROOT, 'dist');
    const stage = join(dist, name);
    rmSync(stage, { recursive: true, force: true });
    mkdirSync(stage, { recursive: true });

    copyFileSync(built, join(stage, PLUGIN));
    for (const doc of DOCS) {
        copyFileSync(join(ROOT, doc), join(stage, doc));
    }

    const archive = `${name}.zip`;
    rmSync(join(dist, archive), { force: true });
    // -r recurse, -q quiet, -X drop the extra file attributes that make an
    // archive differ between machines for no visible reason.
    execFileSync('zip', ['-rqX', archive, name], { cwd: dist });

    console.log(`packaged dist/${archive}`);
    console.log(`  ${PLUGIN}`);
    for (const doc of DOCS) console.log(`  ${doc}`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main();
