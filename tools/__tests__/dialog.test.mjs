import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseMethods } from '../build.mjs';

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

// Each box lists its own copy of the shapes, for the reason each notehead box
// has its own list: nothing documents handing one list node to several boxes.
test('every notehead box has a chart shape box beside it, with a list of its own', () => {
    const msd = readFileSync(join(ROOT, 'src/Settings.msd'), 'utf8');
    const lists = new Set();
    for (const kind of ['bell', 'chime', 'smb', 'pf', 'whitechapel']) {
        const control = msd.match(new RegExp(`ListVar "([^"]+)"[^}]*ID "dlg_${kind}Shape"`));
        assert.ok(control, `no dlg_${kind}Shape box`);
        lists.add(control[1]);
    }
    assert.equal(lists.size, 5, 'two shape boxes share a list');
});

test('the dialog has a notehead box and a colour field for P&F and Whitechapel bells', () => {
    const msd = readFileSync(join(ROOT, 'src/Settings.msd'), 'utf8');
    for (const id of ['dlg_pfHead', 'dlg_whitechapelHead', 'dlg_pfColor', 'dlg_whitechapelColor']) {
        assert.match(msd, new RegExp(`ID "${id}"`), `no ${id} control`);
    }
});

// Picking a notehead fills that instrument's colour field from the music, so
// each coloured instrument's notehead box calls a method of its own. A Method
// naming nothing the plug-in defines fails only when the box is clicked.
test('each coloured notehead box calls a method the plug-in defines', () => {
    const msd = readFileSync(join(ROOT, 'src/Settings.msd'), 'utf8');
    const manifest = JSON.parse(readFileSync(join(ROOT, 'tools/plugins.json'), 'utf8'));
    const plugin = manifest.plugins.find((p) => p.output === 'HandbellsUsedChart.plg');
    const defined = new Set(plugin.sources.flatMap(
        (path) => parseMethods(readFileSync(join(ROOT, path), 'utf8')).map((m) => m.name)));
    for (const kind of ['chime', 'smb', 'pf', 'whitechapel']) {
        const control = msd.match(new RegExp(`ID "dlg_${kind}Head"[^}]*Method "([^"]+)"`));
        assert.ok(control, `dlg_${kind}Head calls no method`);
        assert.ok(defined.has(control[1]), `${control[1]} is not defined`);
    }
});
