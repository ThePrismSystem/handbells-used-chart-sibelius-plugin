# Handbells Used Chart for Sibelius

A Sibelius Ultimate plugin, written in ManuScript, that draws "handbells used" charts into a score.
The charts are placed between the title and the first system in the full score, and can be automatically
added to individual instrument parts if you're writing for dual+ choirs. The plugin can handle handbells,
handchimes, silver melody bells, Petit & Fritsen bells, and/or Whitechapel bells - all charted separately.

- Bells/chimes/etc are listed in pitch order, with same bell accidentals (e.g. G#5 and Ab5) listed
  as both spellings when both appear in the score. This ensure ringers know when they need to share
  a bell throughout a piece. Note that natural signs are never drawn on the charts
- Handchimes, silver melody bells, P&F bells, and Whitechapel bells can each have charts of their own.
  You can choose in the dialog which notehead maps to which type of bell/chime, from the noteheads the score uses
- Each chart is drawn without stems, with the notehead shape its instrument uses, or in a custom shape you pick
- Handbells, handchimes, P&F bells, and Whitechapel bells are charted on grand staffs. Silver melody bells are
  charted on a single treble staff, because there are no SMBs below C5
- Bells/chimes above C7 and below C3 share the column with the octave below/above it (e.g. D7 and D8 are
  charted in the same column as/above D6; G2 is charted in the same column as/below G3)
- You're able to choose whether to have tbe charts placed only in the full score, or to include a subset
  of applicable charts in individual parts for chosen instruments as well
- Rerunning the plugin will update all applicable charts if any changes to the score have been made.
  There's also an option to remove the charts from the score entirely.
- If the plugin cannot positively identify an existing chart as one it created, it refuses to change/remove
  it and explains why.

## Status

Released and working. Verified inside real Sibelius Ultimate 2026 on macOS and Windows:
the in-Sibelius test suite passes in full, including tests that read a real
score, build a chart into it and its parts, and remove it again.

Two rough edges worth knowing before you run it on work you care about:

- In a part, the chart is drawn on the instrument's own staves, so an
  instrument with only one staff gets no bells or handchimes chart in its
  part. The message at the end of the run names it. See
  [Charts in parts](#charts-in-parts).
- The gap between the title block and the chart is whatever Sibelius's
  automatic spacing gives it, in the full score and in the parts. See
  [Known limitations](#known-limitations).

## Installation

The simplest route is the [latest
release](https://github.com/ThePrismSystem/handbells-used-chart-sibelius-plugin/releases/latest):
download the zip and copy `HandbellsUsedChart.plg` and `Handbells Used
Chart Noteheads.sib` into Sibelius' per-user plugin folder, under a
`Handbells` subfolder. The plugin copies its stemless noteheads from the
`.sib` file, so keep the two together. Without it, charts in any shape but
round are drawn as hollow whole notes. See [Chart shapes](#chart-shapes).

On macOS:

```
~/Library/Application Support/Avid/Sibelius/Plugins/Handbells/
```

On Windows:

```
C:\Users\<username>\AppData\Roaming\Avid\Sibelius\Plugins\Handbells\
```

Create the `Handbells` folder if it isn't there, place the files in the folder,
then restart Sibelius. The subfolder name is the category the plugin appears
under in the Plug-ins gallery, so call it something you will recognise.

### Building it yourself

Requires Node.js 22 or later. There are no dependencies to install.

```
npm run build
```

This writes `build/HandbellsUsedChart.plg` and
`build/HandbellsUsedChartTests.plg`, and `npm run package` assembles the
release zip in `dist/` from the first of them and the notehead file. The
notehead file was made by hand in Sibelius and kept in `build/`, and `npm run
deploy` copies it into the plugin folder with the plug-ins. The test plug-in is a
development tool, so it's never part of a release.

Every pull request's CI run also uploads the built `.plg` files and the
notehead file as a downloadable `plugins` artifact.

## Settings

The plugin's dialog has nineteen controls. The instrument and chart choices
are on the left. On the right, each instrument has a row with a notehead box
and a chart shape box, and the colours and removal come after them.

| Control                    | Effect                                                                                                                                        |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Instruments to chart       | Which of the score's instruments are read; Cmd-click (Ctrl-click on Windows) to pick more than one                                            |
| Charts                     | One combined chart, or a separate chart for each instrument                                                                                   |
| Also add charts to parts   | Puts each instrument's charts into its parts as well                                                                                          |
| Page break after one chart | Starts a part's music on a new page when the part has a single chart section; with two or more (bells and chimes count as two) it always does |
| Notehead in music          | One box per instrument: which notehead in the score counts as a handbell, handchime, SMB, P&F bell or Whitechapel bell                        |
| Chart shape                | One box per instrument: the shape its chart is drawn in, or `(match notehead)` to follow the notehead in the music                            |
| Handchime colour           | Notehead colour for chimes, as a hex value, filled in from the music when you pick their notehead; blank leaves them black                    |
| SMBs colour                | Notehead colour for SMBs, same explanation as above                                                                                           |
| P&F colour                 | Notehead colour for P&F bells, same explanation as above                                                                                      |
| Whitechapel colour         | Notehead colour for Whitechapel bells, same explanation as above                                                                              |
| Remove existing chart      | Removes all charts generated by the plugin from the score instead of adding them                                                              |

Section labels are generated: "Handbells Used: _n_", "Handchimes Used: _n_",
"SMBs Used: _n_", "P&F Handbells Used: _n_", "Whitechapel Handbells Used:
_n_". Each counts physical bells, so a bell appearing under two
spellings is counted once, although it is charted under both. They are
ordinary staff text once the chart is drawn, so retype them in the score if
you want to use different labels.

### Choosing the instruments

The list names every instrument in the score, leaving out an existing chart's
own staves. Two instruments with the same name are told apart as `Handbells`,
`Handbells (2)`. Only the selected instruments are read, so a piano or other
accompaniment written with plain noteheads can be left out rather than charted
as handbells. A passage selection still narrows that further to the bars and
staves selected.

The instruments you leave out are remembered by name, across scores: a piano
left out of one score starts left out of the next score that has a piano. An
instrument the plugin has not seen before starts selected, so on a first run
every instrument is.

With one combined chart, the selected instruments are pooled into one set of
sections. With a separate chart for each instrument, each gets its own
sections, stacked in the full score in score order and labelled with the
instrument's name (e.g. "Handbells I - Handbells Used: 25"). The choice only
applies with two or more instruments selected. With separate charts, an
instrument that turns out to have nothing to chart is named in the message
at the end of the run.

### Charts in parts

With "Also add charts to parts" ticked, each part shows the charts of the
instruments it holds. A part holding two choirs gets both choirs' charts, an
instrument with no part of its own appears only in the full score, and a
part holding no selected instrument gets no chart. The full score always
carries every chart, because the chart bars are bars of the whole score.

The chart in a part is a copy, drawn on the instrument's own staves in the
chart bars, shown only in the parts and silent in playback. The full score
keeps its chart on staves of its own and hides the copies. The plugin never
adds a staff to a part. Sibelius resets a part's title block and its staff
spacing whenever a staff is added to the part, so leaving the part's staves
alone is what keeps its layout and title block as they were, through a
build, a re-run and a removal.

A copy needs staves that can hold it. Bells and handchimes charts use a
treble and a bass staff, so they go on an instrument's top two staves, and
an instrument with one staff gets none. A silver melody bells chart needs
one staff. A percussion or tab staff can't hold a chart at all. The message
at the end of the run names any instrument left without a chart in its part
for this reason.

The copy prints with no key signature and in treble and bass clefs, as the
chart does. In a score whose key has sharps or flats, the chart bars are set
in C major and the music starts with its own key as an ordinary key change,
in the full score and in every part. Removing the chart puts the music's key
back at its start. Where an instrument's own clef differs from the copy's,
the plugin changes it for the chart bars and puts it back where the music
starts, and removing the chart takes those clef changes off again.

In a part that carries one instrument's charts, the labels are the plain
"Handbells Used: 25", since the part's name already says whose they are. In
a part holding several instruments they keep the instrument names. A copy
sits on the instrument's own staff, which is the same staff in every part
that holds it, so a chart that sits in both kinds of part keeps its names in
all of them.

In a part, each chart is a system of its own showing only the staves that
hold it. Other instruments' charts drop out of the part: its staves change
to "No instrument (hidden)" for those bars and change back for its own
charts and for the music, with the change labels hidden. Removing the chart
takes those changes off again and gives every staff its own instrument and
name back. Sibelius keeps at least one staff showing in every system, so in
a part with a staff that holds no chart, such as an instrument that isn't
charted, another instrument's chart joins the part's own chart as a short
empty bar instead.

A part's first page is often laid out by hand, with its page turns planned,
and charts in front of it push music off that page. Each chart section is a
system of its own, and an instrument's bells and chimes are two sections. In
a part with two or more sections, the music therefore starts on a new page,
laid out as it was, one page later. In a part with one section, the music
follows the chart on the first page unless "Page break after one chart" is
enabled.

After that page break the music starts on a left-hand page instead of a
right-hand one. If the part uses mirrored or different page margins in
Document Setup, that page takes the left-hand margins and sits further left
than the old first page did, as every left-hand page in the part already
does. To keep the music on the same left- or right-hand pages as before, add
a blank page after the chart in Sibelius.

### Colours

The four colour fields take a **six-digit hex RGB value**, with or without the
leading `#`, and surrounding spaces are ignored. All of `c00000`, `#c00000`
and `#C00000` set the same red. A blank field charts with the default
color (black).

The fields fill themselves in from the music. When you pick a notehead for
handchimes, SMBs, P&F bells, or Whitechapel bells, that instrument's colour
field takes the colour most of the notes in that notehead carry, so a few
notes left black among red ones still give red. A notehead whose notes are
mostly black leaves the field blank. You can type over the field afterwards,
and picking another notehead fills it in again. When the dialog opens, a
field that was blank on your last run takes the colour of the notehead its
box opens on, and any other field keeps the colour from your last run. To
chart an instrument with coloured noteheads in black, clear its field before
you run.

Anything that is not six digits after the `#` counts as no colour at all, so
that section stays black rather than the run failing. Within a six-digit
value, a character that is not a hex digit reads as `0`: `zz0000` is accepted
and comes out black rather than being refused.

### Choosing the noteheads

All five notehead dropdowns are filled from the open score each time the
dialog opens: they list the notehead styles the music actually uses, plus
a `(no notehead)` entry meaning that instrument is not in this piece.

The boxes open on the plain notehead for handbells and the diamond for
handchimes wherever the score uses them, which is what the plugin assumed
before these controls existed. The SMB, P&F and Whitechapel boxes have no
default, so they open on `(no notehead)` until you select one. Your last
choice is remembered between runs, but only while the score still uses it.
Picking a notehead also fills in that instrument's colour field.
See [Colours](#colours).

Notes carrying a notehead none of the five boxes names are skipped and
counted in the unrecognised-notehead warning, which names the heads it
skipped so you can see which entry to pick. No two instruments may share a
notehead: the plugin says which one clashes and charts nothing, rather than
reading those notes as two instruments at once.

## Chart shapes

Chart notes carry no stems, and each instrument's chart is drawn in one of
the seven shapes below. The chart shape box beside each notehead box picks
the shape. It opens on `(match notehead)`, which draws the chart in the
shape of the notehead the music uses for that instrument, so handchimes
written as diamonds are charted as diamonds. Your last choice is remembered
between runs.

|                                                                             | Shape                         | Chart notehead                 | Sibelius' own noteheads of this shape                                  |
| --------------------------------------------------------------------------- | ----------------------------- | ------------------------------ | ---------------------------------------------------------------------- |
| <img src="docs/shapes/round.svg" alt="" width="40" height="28">             | Round                         | `Stemless`, built in           | Normal, stemless, cue, silent, slashed and back-slashed, shaped note 5 |
| <img src="docs/shapes/diamond.svg" alt="" width="40" height="28">           | Diamond                       | `Diamond (stemless)`           | Diamond, black and white diamond, shaped note 3                        |
| <img src="docs/shapes/square.svg" alt="" width="40" height="28">            | Square                        | `Square (stemless)`            | Shaped note 6                                                          |
| <img src="docs/shapes/triangle.svg" alt="" width="40" height="28">          | Triangle, point up            | `Triangle (stemless)`          | Shaped notes 1 and 4, up arrow                                         |
| <img src="docs/shapes/inverted-triangle.svg" alt="" width="40" height="28"> | Inverted triangle, point down | `Inverted triangle (stemless)` | Inverted triangle, down arrow                                          |
| <img src="docs/shapes/half-circle.svg" alt="" width="40" height="28">       | Half circle, flat side up     | `Half circle (stemless)`       | Shaped note 2                                                          |
| <img src="docs/shapes/cone.svg" alt="" width="40" height="28">              | Cone, point down              | `Cone (stemless)`              | Shaped note 7                                                          |

ManuScript can't see what a notehead looks like, only its number and its
name, so the plugin works the shape out from those:

- Sibelius' own noteheads have the same shape in every score and every
  language, so the plugin reads them by number, as the last column lists.
  Shaped note 4 is a right triangle, which counts as a triangle.
- A notehead made by hand is read by its name. Sibelius names a copy after
  the head it came from, such as `Black & white diamond (2)`, so a name
  containing diamond, square, triangle, inverted, half circle, cone,
  normal, round or stemless gives the shape. Only English names are read.

When the plugin can't determine the shape of the notehead used, handchimes
are charted as diamonds, SMBs as squares, and every other instrument as
round. To change this, select a different notehead shape.

Round charts use Sibelius' built-in `Stemless` notehead, which every score
has. The other shapes need stemless noteheads that Sibelius doesn't ship
and ManuScript can't create, so they come from the notehead file,
`Handbells Used Chart Noteheads.sib`, which needs to be in the same folder
as the plugin. When a score lacks one, the plugin opens the file, copies a
note in that notehead into the score and closes the file. A score that
already has a notehead by one of the names in the table uses its own.

If the file isn't included in the Handbells plugin folder, or a notehead
can't be copied from it, the chart notes will still be stemless. That
instrument's notes are written as whole notes in Sibelius' own notehead
of that shape, since a whole note has no stem. The cost is that a whole
note's head is hollow, so the chart reads as outlined shapes. The message
at the end of the run names the instrument, the missing notehead and the file.

## Usage

Running the plugin on a score that already carries a chart it made replaces
that chart rather than adding a second one, in the parts as well as the full
score. Checking "Remove existing chart" in the dialog strips the chart
instead of drawing one, from the parts too; the instrument, chart and parts
choices make no difference to a removal.

The plugin works on the full score even when it is run while a part is open,
and leaves that part open afterwards.

The title block stays on the first page with the chart, and so does any text
in a blank-page style, such as a copyright line. Tempo marks and other
directions at the start of the piece move down to its first bar of music,
and the piece keeps its own bar numbers. Removing the chart moves the title
block to the first bar of music with the positions it had, including a title
placed partly off the page.

The chart makes the music start a new section, and Sibelius takes the
instrument names there from a separate Engraving Rules option, the one for
the start of new sections. While a chart is in the score, the plugin sets
that option to match the one for the first system, so the first system of
music is named as the score's first system would be. Any other section
starts in the piece follow it too. Removing the chart puts the score's own
setting back. If a chart can no longer be identified, the plugin still puts
this setting back before asking you to delete the chart by hand.

## Testing

**CI builds and lints only. It cannot run the plugin.** Sibelius has no
headless mode, no Linux build and no command-line interface, so nothing in
this project can be executed by a CI runner.

The real tests are a second plugin, `HandbellsUsedChartTests.plg`, built
from the same `src/` sources plus `test/*.mss`. It is run by hand inside
Sibelius, and reports pass/fail counts to the plugin trace window. It
covers bell naming and region boundaries, collection and enharmonic handling,
column anchoring and stacking, plan assembly, the dialog's options, chart
shapes, copying a notehead in from the notehead file, instrument and part
planning, and score-level runs that build a chart into a real score and its
parts then remove it again.

The score-level tests run on whatever score is open, and the parts tests
need two instruments that each have a part of their own. The notehead test
needs `Handbells Used Chart Noteheads.sib` installed beside the plugin.

## Known limitations

- Sibelius Ultimate 2026 or later. `Initialize` checks
  `Sibelius.ProgramVersion` and declines to register the plugin on an older
  release rather than failing obscurely partway through a run.
- Handbells sound an octave above written pitch. Sibelius has no transposing
  handbell instrument, so the plugin applies that octave itself.
- An instrument is recognised from the number of staves Sibelius gave it when
  it was created, and from its instrument type. One given an extra staff by
  hand may be listed as two. One that lost a staff by hand can take in the
  next instrument's first staff when both are the same type.
- In a part, the chart is drawn on the instrument's own staves, so the
  instrument's brace shows beside it. Sibelius sets braces for a whole part,
  not for one system.
- With one combined chart, a part holding two charted instruments shows the
  chart twice, once on each instrument's staves. A part can't hide a staff
  that holds notes it shows.
- Sibelius's Optimize Staff Spacing is run over the chart and, in the full
  score, the first system of music, which replaces any staff spacing set on
  those systems by hand. In a part it runs over the chart alone.
- The plugin doesn't make room between the title block and a chart. A
  chart's label, or high bells on ledger lines, can reach the composer lines
  in the full score or in a part. If they do, select the title lines in
  Sibelius and move them up (or select the chart and move it down).
- One notehead per kind of bell. A score marking its handchimes with two
  different diamond styles has to be normalised first. Notes carrying the
  head that was not chosen are skipped and counted toward the
  unrecognised-notehead warning.
- Handbells are currently charted as black only.
- Bells outside C2-C9 are skipped and reported as a warning rather than
  charted.
- The chart adds a system per section to the first page, which can push the
  page over the threshold at which Sibelius draws system separators (the
  double slash at the left margin between systems). That is an engraving
  rule, not something the chart draws, and ManuScript exposes no way to set
  it. You can turn it off in Engraving Rules, on the Instruments page, under
  System separators.
- ManuScript has no exception handling. If a run hits a hard error partway
  through, the score's redraw can stay disabled until Sibelius is
  restarted.
- The plugin calls `utils.IsNumeric`, `utils.LowerCase` and
  `utils.DeleteStaff` from `utils.plg`, which Sibelius installs and intends
  other plugins to call. A Sibelius installation missing that plugin will
  fail on those calls.
- Plugin actions may not be undoable as a single step; Sibelius warns about
  this for plugins generally.

## Licence

GPL-3.0-only. See [LICENSE.md](LICENSE.md).
