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

// A control whose Value names no Data variable, or a dlg_ variable with no
// control, fails only when Sibelius opens the dialog. Every notehead box also
// needs the list variable it is filled from.
test('every dlg_ variable has a control and every control a variable', () => {
    const msd = readFileSync(join(ROOT, 'src/Settings.msd'), 'utf8');
    const values = [...msd.matchAll(/^\t+Value "([^"]+)"/gm)].map((m) => m[1]).sort();
    const lists = [...msd.matchAll(/^\t+ListVar "([^"]+)"/gm)].map((m) => m[1]);
    const manifest = JSON.parse(readFileSync(join(ROOT, 'tools/plugins.json'), 'utf8'));
    for (const entry of manifest.plugins) {
        const declared = Object.keys(entry.data).filter((k) => k.startsWith('dlg_')).sort();
        assert.deepEqual(values, declared, `${entry.output} and the dialog disagree`);
        for (const list of lists) {
            assert.ok(list in entry.data, `${entry.output} lacks ${list}`);
        }
    }
});

test('the dialog has a notehead box and a colour field for P&F and Whitechapel bells', () => {
    const msd = readFileSync(join(ROOT, 'src/Settings.msd'), 'utf8');
    for (const id of ['dlg_pfHead', 'dlg_whitechapelHead', 'dlg_pfColor', 'dlg_whitechapelColor']) {
        assert.match(msd, new RegExp(`ID "${id}"`), `no ${id} control`);
    }
});
