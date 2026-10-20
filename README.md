# Handbells Used Chart for Sibelius

A Sibelius Ultimate plugin, written in ManuScript, that draws a "handbells
used" chart into a score: a grand staff, placed between the title and the
first system, listing every distinct handbell and handchime the piece needs.

It is a port of
[handbells-used-chart-musescore-extension](https://github.com/ThePrismSystem/handbells-used-chart-musescore-extension)
to Sibelius. The chart's behaviour is unchanged from that project:

- Bells are listed in pitch order, spelled the way the score spells them. A
  bell the piece writes as both G#5 and Ab5 gets a column for each spelling,
  each with its own accidental. That is deliberate, not a failure to
  deduplicate: the two spellings are one physical bell, and they fall to
  different positions, so the chart is how the F5-G5 ringer and the A5-B5
  ringer see that they have to share it.
- No natural sign is ever drawn on the chart. Sibelius adds one to a plain E
  a few columns along from an E flat, where it reads as cancelling that flat
  rather than naming a bell of its own. Which bells are charted is unaffected:
  E flat and E are two separate bells and get a column each either way.
- Handchimes and silver melody bells get charts of their own. Which
  notehead means which instrument is chosen in the dialog from the noteheads
  the score actually uses, so an arrangement that marks them some other way
  charts as readily as one using the conventional heads.
- Handbells and handchimes are charted on a treble and a bass staff. Silver
  melody bells are a treble set, so they get a single treble staff, C5
  included, which is how they are usually printed and one staff less on the
  page.
- A bell that also appears an octave or two higher shares its column, so D6,
  D7 and D8 print as one stack rather than three.
- A score with several handbell parts can be charted one instrument at a
  time, and each instrument's charts can go into its Sibelius part as well as
  the full score. Instruments that are not handbells, such as a piano, can be
  left out.
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
download the zip and copy `HandbellsUsedChart.plg` into Sibelius' per-user
plugin folder, under a `Handbells` subfolder.

On macOS:

```
~/Library/Application Support/Avid/Sibelius/Plugins/Handbells/
```

On Windows:

```
C:\Users\<username>\AppData\Roaming\Avid\Sibelius\Plugins\Handbells\
```

Create the `Handbells` folder if it isn't there, then restart Sibelius. The
subfolder name is the category the plugin appears under in the Plug-ins
gallery, so call it something you will recognise.

### Building it yourself

Requires Node.js 22 or later. There are no dependencies to install.

```
npm run build
```

This writes `build/HandbellsUsedChart.plg` and
`build/HandbellsUsedChartTests.plg`, and `npm run package` assembles the
release zip in `dist/` from the first of them. The test plug-in is a
development tool. It builds a real chart on the open score and removes it
again, so it is never part of a release.

Every pull request's CI run also uploads the built `.plg` files as a
downloadable `plugins` artifact.

## Settings

The plugin's dialog offers nine controls:

| Control | Effect |
|---|---|
| Instruments to chart | Which of the score's instruments are read; Cmd-click (Ctrl-click on Windows) to pick more than one |
| Charts | One combined chart, or a separate chart for each instrument |
| Also add charts to parts | Puts each instrument's charts into its parts as well |
| Handbell notehead type | Which notehead in the score counts as a handbell |
| Handchime notehead type | Which notehead in the score counts as a handchime |
| SMBs notehead type | Which notehead in the score counts as a silver melody bell |
| Handchime colour | Notehead colour for chimes, as a hex value; blank leaves them black |
| SMBs colour | Notehead colour for SMBs, on the same terms |
| Remove existing chart | Strips the chart instead of generating one |

Section labels are generated: "Handbells Used: *n*", "Handchimes Used: *n*",
"SMBs Used: *n*". Each counts physical bells, so a bell appearing under two
spellings is counted once, although it is charted under both. They are
ordinary staff text once the chart is drawn, so retype them in the score if
you want something else.

### Choosing the instruments

The list names every instrument in the score, by the name it carries there,
leaving out an existing chart's own staves. Two instruments with the same name
are told apart as `Handbells`, `Handbells (2)`. Only the selected instruments
are read, so a piano or other accompaniment written with plain noteheads can
be left out rather than charted as handbells. A passage selection still
narrows that further to the bars and staves selected.

The instruments you leave out are remembered by name, across scores: a piano
left out of one score starts left out of the next score that has a piano. An
instrument the plugin has not seen before starts selected, so on a first run
everything is, which charts exactly what earlier versions did.

With one combined chart, the selected instruments are pooled into one set of
sections, as before. With a separate chart for each instrument, each one gets
its own sections, stacked in the full score in score order and labelled with
the instrument's name: "Handbells I - Handbells Used: 25". The choice only
applies with two or more instruments selected. An instrument that turns out
to have nothing to chart is named in the message at the end of the run.

### Charts in parts

With "Also add charts to parts" ticked, each chart also goes into the parts
that hold the instrument it belongs to. A part holding two choirs gets both
choirs' charts; an instrument with no part of its own appears only in the
full score; a part holding no selected instrument gets no chart. The full
score always carries every chart, because the chart bars are bars of the
whole score.

In a part that carries one instrument's charts, the labels are the plain
"Handbells Used: 25", since the part's name already says whose they are. In a
part holding several instruments they keep the instrument names. A chart
staff is the same staff in the score and in every part that shows it, so a
chart that sits in both kinds of part keeps its names in all of them.

Each part that carries a chart is laid out to show its own charts, each on a
system of its own, and nothing where another instrument's chart sits. A part
that carries none is left as it was. Sibelius may give every instrument the
plugin adds a part of its own; any part holding nothing but chart staves is
deleted, on a build and on a removal.

### Colours

The two colour fields take a **six-digit hex RGB value**, with or without the
leading `#`, and surrounding spaces are ignored. All of `c00000`, `#c00000`
and ` #C00000 ` set the same red. Leave a field blank to keep that section
black, which is what handbells always are.

Anything that is not six digits after the `#` counts as no colour at all, so
that section stays black rather than the run failing. Within a six-digit
value, a character that is not a hex digit reads as `0`: `zz0000` is accepted
and comes out black rather than being refused, so blank is the clearer way to
ask for black.

### Choosing the noteheads

All three notehead dropdowns are filled from the open score each time the
dialog opens: they list the notehead styles the music actually uses, by the name
Sibelius knows them under, plus a `(no notehead)` entry meaning that
instrument is not in this piece. An existing chart's own staves are left out
of the scan, so re-running never offers the chart's noteheads back.

The boxes open on the plain notehead for handbells and the diamond for
handchimes wherever the score uses them, which is what the plugin assumed
before these controls existed. The SMBs box has no such default, because
nothing in a score suggests one, so it opens on `(no notehead)` until you
pick. Your last choice is remembered between runs and wins over the
defaults, but only while the score in front of you still uses it.

Notes carrying a notehead none of the three boxes names are skipped and
counted in the unrecognised-notehead warning, which names the heads it
skipped so you can see which entry to pick. No two instruments may share a
notehead: the plugin says which one clashes and charts nothing, rather than
reading those notes as two instruments at once.

## The handchime and SMB noteheads

Chart notes carry no stems. Handbells use Sibelius' built-in `Stemless`
notehead, which every score has. Handchimes need a stemless *diamond* and
SMBs a stemless *square*, and Sibelius ships neither. Its diamond styles all
carry stems, it has no square notehead at all, and ManuScript cannot create a
notehead style, so the plugin cannot make either one for you.

Make them once, by hand, and every score you apply that house style to gets
them:

1. **Notations → Noteheads → Edit Noteheads**.
2. Select **Diamond** and click **New**, which starts a copy of it.
3. Name the copy exactly **`Diamond (stemless)`**.
4. Switch off **Stems** (and **Ledger lines**, if you prefer the published
   look), then click OK.
5. For SMBs, select **Shaped note 6** (the square) and click **New**, name
   the copy exactly **`Square (stemless)`**, and switch **Stems** off the
   same way.

The plugin looks each notehead up by name and uses it when it is there. To
use different names, change `STEMLESS_DIAMOND` and `SQUARE_STEMLESS` in
`tools/plugins.json` and rebuild.

Without them the plugin still produces a stemless chart: those columns are
written as whole notes instead, which carry no stems at any notehead style.
Handchimes fall back to Sibelius' built-in **Diamond** and SMBs to **Shaped
note 6**, which is the square. The cost is that a whole note's head is hollow
rather than filled, so those sections read as outlined shapes. Either missing
notehead is reported in a warning naming the instrument and the notehead to
make. Handbells are unaffected either way.

## Usage

Running the plugin on a score that already carries a chart it made replaces
that chart rather than adding a second one, in the parts as well as the full
score. Checking "Remove existing chart" in the dialog strips the chart
instead of drawing one, from the parts too; the instrument, chart and parts
choices make no difference to a removal.

The plugin works on the full score even when it is run while a part is open,
and leaves that part open afterwards.

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

- Sibelius Ultimate 2026 or later. `Initialize` checks
  `Sibelius.ProgramVersion` and declines to register the plugin on an older
  release rather than failing obscurely partway through a run.
- Developed and tested on macOS. Nothing in the ManuScript is
  platform-specific and it should behave the same on Windows, but that is
  untested, so treat Windows as unverified rather than supported. Only
  `npm run deploy`, a convenience for copying a fresh build into place, is
  macOS-only.
- Handbells sound an octave above written pitch. Sibelius has no transposing
  handbell instrument, so the plugin applies that octave itself.
- An instrument is recognised from the number of staves Sibelius gave it when
  it was created. One given an extra staff by hand may be listed as two.
- Many instruments make many charts: each chart section is a system of its
  own before the music, so five instruments with bells and chimes put ten
  systems ahead of bar 1, running onto later pages.
- One notehead per kind of bell, and three kinds at most. A score
  marking its handchimes with two different diamond styles has to be charted
  twice, or normalised first; notes carrying the head that was not chosen
  are counted toward the unrecognised-notehead warning.
- Handbells take no colour of their own. They are the reference the other
  two sections are read against, so they are always black.
- Bells outside C2-C9 are skipped and reported as a warning rather than
  charted.
- The chart adds a system per section to the first page, which can push the
  page over the threshold at which Sibelius draws system separators, the
  double slash at the left margin between systems. That is an engraving
  rule, not something the chart draws, and ManuScript exposes no way to set
  it: turn it off in Engraving Rules, on the Instruments page, under System
  separators.
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
