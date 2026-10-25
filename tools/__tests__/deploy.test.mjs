import { test } from 'node:test';
import assert from 'node:assert/strict';
import { pluginDir, deployable } from '../deploy.mjs';

test('resolves the macOS per-user plugin folder', () => {
    assert.equal(
        pluginDir('darwin', '/Users/me'),
        '/Users/me/Library/Application Support/Avid/Sibelius/Plugins/Handbells'
    );
});

test('refuses platforms it has no folder for, and says where to copy by hand', () => {
    assert.throws(() => pluginDir('linux', '/home/me'), /only knows the macOS plugin folder/);
    assert.throws(() => pluginDir('win32', 'C:\\Users\\me'), /Avid\\Sibelius\\Plugins\\Handbells/);
});

test('deploys the plug-ins and the notehead file they copy noteheads from', () => {
    assert.equal(deployable('HandbellsUsedChart.plg'), true);
    assert.equal(deployable('Handbells Used Chart Noteheads.sib'), true);
    assert.equal(deployable('.DS_Store'), false);
});
