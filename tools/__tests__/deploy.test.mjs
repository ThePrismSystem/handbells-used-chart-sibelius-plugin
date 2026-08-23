import { test } from 'node:test';
import assert from 'node:assert/strict';
import { pluginDir } from '../deploy.mjs';

test('resolves the macOS per-user plugin folder', () => {
    assert.equal(
        pluginDir('darwin', '/Users/me'),
        '/Users/me/Library/Application Support/Avid/Sibelius/Plugins/Handbells'
    );
});

test('refuses unsupported platforms', () => {
    assert.throws(() => pluginDir('linux', '/home/me'), /only runs on macOS/);
});
