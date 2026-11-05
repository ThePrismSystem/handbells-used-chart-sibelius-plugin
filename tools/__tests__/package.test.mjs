import { test, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { packageRelease } from '../package.mjs';

let root;

function makeRoot(files) {
    root = mkdtempSync(join(tmpdir(), 'hbuc-pkg-'));
    writeFileSync(join(root, 'package.json'), '{"version":"9.9.9"}');
    for (const name of files) {
        mkdirSync(join(root, name, '..'), { recursive: true });
        writeFileSync(join(root, name), name);
    }
    return root;
}

afterEach(() => {
    rmSync(root, { recursive: true, force: true });
});

test('refuses to package before the plug-in is built', () => {
    makeRoot([]);
    assert.throws(() => packageRelease(root), /is not built/);
});

test('stages the plug-in, the notehead file and the docs, and zips them', () => {
    makeRoot([
        'build/HandbellsUsedChart.plg',
        'build/HandbellsUsedChartTests.plg',
        'build/Handbells Used Chart Noteheads.sib',
        'README.md',
        'LICENSE.md',
        'CHANGELOG.md'
    ]);
    const { archive, files } = packageRelease(root);
    assert.deepEqual(files, [
        'HandbellsUsedChart.plg',
        'Handbells Used Chart Noteheads.sib',
        'README.md',
        'LICENSE.md',
        'CHANGELOG.md'
    ]);
    assert.equal(archive, join(root, 'dist', 'handbells-used-chart-v9.9.9.zip'));
    assert.ok(existsSync(archive));
    assert.ok(!existsSync(join(root, 'dist', 'handbells-used-chart-v9.9.9', 'HandbellsUsedChartTests.plg')));
});
