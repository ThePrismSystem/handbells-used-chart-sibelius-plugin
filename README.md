# Handbells Used Chart for Sibelius

A Sibelius Ultimate plugin, written in ManuScript, that draws a "handbells
used" chart into a score: a grand staff, placed between the title and the
first system, listing every distinct handbell and handchime the piece needs.

It is a port of
[handbells-used-chart-musescore-extension](https://github.com/ThePrismSystem/handbells-used-chart-musescore-extension)
to Sibelius. The chart's behaviour is unchanged from that project:

- Bells are listed in pitch order, spelled the way the score spells them. A
  bell written as both G#5 and Ab5 in the piece appears under both spellings,
  because a ringer reads the chart to plan position splits, and the spelling
  tells the next position over whether it has to share a bell.
- No natural sign is ever drawn on the chart. A plain E a few columns along
  from an E flat would otherwise read as picking up a natural and be counted
  as a second, separate bell.
- Handchimes get a chart of their own, distinguished by diamond noteheads.
- A bell that also appears an octave or two higher shares its column, so D6,
  D7 and D8 print as one stack rather than three.
- Running the plugin again on a score that already carries a chart replaces
  it rather than adding a second one.
- If the plugin cannot positively identify an existing chart as its own, it
  refuses to touch it and explains why, rather than guessing.

## Status

Released and working. Verified inside real Sibelius Ultimate 2026 on macOS:
the in-Sibelius test suite passes 109 of 109 assertions, including tests that
read a real score, build a chart into it, and remove it again.

Two rough edges worth knowing before you run it on work you care about:

- Removing a chart returns the score's title block to Sibelius's default
  positions for those text styles. The content, styling and visibility all
  survive; hand positioning does not. Building a chart never touches it.
- The gap between the title block and the chart is whatever Sibelius's
  automatic spacing gives it.

## Installation

The simplest route is the [latest
release](https://github.com/ThePrismSystem/handbells-used-chart-sibelius-plugin/releases/latest):
download the zip, and copy `HandbellsUsedChart.plg` into

```
~/Library/Application Support/Avid/Sibelius/Plugins/Handbells/
```

(creating the `Handbells` folder if it doesn't exist yet), then restart
Sibelius so it picks up the new plugin.

### Building it yourself

Requires Node.js 22 or later. There are no dependencies to install.

```
npm run build
```

This writes `build/HandbellsUsedChart.plg` and
`build/HandbellsUsedChartTests.plg`, and `npm run package` assembles the
release zip in `dist/` from the first of them. The test plug-in is a
development tool — it builds a real chart on the open score and removes it
again — so it is never part of a release.

Every pull request's CI run also uploads the built `.plg` files as a
downloadable `plugins` artifact.

## Settings

The plugin's dialog is meant to offer four controls:

| Control | Effect |
|---|---|
| Handbell label | Replaces the generated "Handbells Used: *n*" |
| Handchime label | Replaces the generated "Handchimes Used: *n*" |
| Handchime colour | Notehead colour for chimes, e.g. `#c00000`; left blank, chimes stay black |
| Remove existing chart | Strips the chart instead of generating one |

An unparseable colour leaves the chimes black rather than failing the run.
Each label counts physical bells, so a bell appearing under two spellings is
counted once.

## The handchime notehead

Chart notes carry no stems. Handbells use Sibelius' built-in `Stemless`
notehead, which every score has. Handchimes need a stemless *diamond*, and
Sibelius ships no such notehead — its diamond styles all carry stems, and
ManuScript cannot create a notehead style, so the plugin cannot make one for
you.

Make it once, by hand, and every score you apply that house style to gets it:

1. **Notations → Noteheads → Edit Noteheads**.
2. Select **Diamond** and click **New**, which starts a copy of it.
3. Name the copy exactly **`Diamond (stemless)`**.
4. Switch off **Stems** (and **Ledger lines**, if you prefer the published
   look), then click OK.

The plugin looks the notehead up by that name and uses it when it is there.
To use a different name, change `STEMLESS_DIAMOND` in `tools/plugins.json`
and rebuild.

Without it, the plugin still produces a stemless chart: chime columns are
written as whole notes instead, which carry no stems at any notehead style.
The cost is that a whole note's head is hollow rather than filled, so the
chimes read as outlined diamonds. Handbells are unaffected either way.

## Usage

Running the plugin on a score that already carries a chart it made replaces
that chart rather than adding a second one. Checking "Remove existing chart"
in the dialog strips the chart instead of drawing one.

## Testing

**CI builds and lints only. It cannot run the plugin.** Sibelius has no
headless mode, no Linux build and no command-line interface, so nothing in
this project can be executed by a CI runner.

The real tests are a second plugin, `HandbellsUsedChartTests.plg`, built
from the same `src/` sources plus `test/*.mss`. It is run by hand inside
Sibelius Ultimate 2026 on macOS, and reports pass/fail counts to the trace
window. As of this writing it passes 109 of 109 assertions, covering bell
naming and region boundaries, collection and enharmonic handling, column
anchoring and stacking, plan assembly, and score-level runs that build a
chart into a real score and remove it again.

## Known limitations

- macOS and Sibelius Ultimate 2026 only. `Initialize` checks
  `Sibelius.ProgramVersion` and declines to register the plugin on an older
  release rather than failing obscurely partway through a run.
- Handbells sound an octave above written pitch. Sibelius has no transposing
  handbell instrument, so the plugin applies that octave itself.
- Only `DiamondNoteStyle` is read as a handchime notehead. Sibelius has two
  other diamond-like notehead styles, `CrossOrDiamondNoteStyle` and
  `BlackAndWhiteDiamondNoteStyle`; notes using either are counted toward the
  unrecognised-notehead warning instead of being read as chimes.
- Bells outside C2-C9 are skipped and reported as a warning rather than
  charted.
- ManuScript has no exception handling. If a run hits a hard error partway
  through, the score's redraw can stay disabled until Sibelius is
  restarted.
- The plugin calls `utils.IsNumeric` and `utils.DeleteStaff` from `utils.plg`,
  which Sibelius installs and intends other plugins to call. A Sibelius
  installation missing that plugin will fail on those calls.
- Bells above C7 are drawn in Sibelius's out-of-range colour on screen, since
  `InstrumentType` exposes no minimum or maximum pitch to a plugin; print is
  unaffected.
- Ledger lines run continuously from the staff to each stacked bell.
  Published charts use detached ledger lines, which this plugin does not
  draw.
- Plugin actions may not be undoable as a single step; Sibelius warns about
  this for plugins generally.

## Licence

GPL-3.0-only. See [LICENSE.md](LICENSE.md). The note-reading logic descends
from the [handbell-notation](https://github.com/andy-lyttle/handbell-notation)
plugins, copyright 2025 Andy Lyttle, used under the GPL-3.0.
