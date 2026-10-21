import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');

// Sibelius.EnableNthControl is the only way to grey a control out before the
// dialog opens, and it names the control by its 0-based creation order, which
// is the order the controls are written in the .msd. Moving a control there
// silently greys out the wrong one, so the index is pinned to the file here.
test('CHART_MODE_CONTROL_INDEX is the Charts box in the dialog creation order', () => {
    const msd = readFileSync(join(ROOT, 'src/Settings.msd'), 'utf8');
    const ids = [...msd.matchAll(/^\t+ID "([^"]+)"/gm)].map((m) => m[1]);
    const manifest = JSON.parse(readFileSync(join(ROOT, 'tools/plugins.json'), 'utf8'));
    for (const entry of manifest.plugins) {
        assert.equal(entry.data.CHART_MODE_CONTROL_INDEX, String(ids.indexOf('dlg_chartMode')),
            `${entry.output} names the wrong control`);
    }
});
