# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Scores with several handbell parts can chart each one separately, and put
each chart into the Sibelius part that rings from it. P&F and Whitechapel
handbells get charts of their own.

### Added

- An "Instruments to Chart" list in the dialog, filled from the open score,
  chooses which instruments are read. A piano or other accompaniment written
  with plain noteheads used to be charted as handbells; now it can be left
  out. The plug-in remembers the instruments left out by name, so one left
  out of one score stays out of the next score that has it. An instrument
  it has not seen before starts selected.
- A "Charts" choice between one combined chart, as earlier versions drew,
  and a separate chart for each instrument. Separate charts are stacked in
  the full score in score order and labelled with the instrument's name:
  `Handbells I - Handbells Used: 25`. The choice applies once two or more
  instruments are selected.
- "Also Add Charts to Parts" gives each part the charts of the instruments
  it holds, each chart on a system of its own. The full score always
  carries every chart. In a part, the chart is a copy drawn on the
  instrument's own staves, shown only in the parts and silent in playback.
  No staff is added to a part, because Sibelius resets a part's title block
  and staff spacing when one is, so a part keeps its layout. An instrument
  with one staff gets no bells or handchimes chart in its part, a
  percussion or tab staff gets none at all, and the message at the end of
  the run names them. In a part holding one instrument the labels are the
  plain `Handbells Used: 25`; in a part holding several they keep the
  instrument names. Other instruments' charts ahead of a part's last chart
  drop out of the part, because its staves change to "No instrument
  (hidden)" for those bars. One after its last chart shows as a short empty
  bar beside it, since Sibelius keeps a staff showing in every system. A
  part holding no
  selected instrument gets no chart, and the message at the end of the run
  says so when the box is ticked but no part holds a selected instrument.
- In a part given two or more chart sections, the music starts on a new
  page, laid out as it was, because charts added in front of a full first
  page push music off it. An instrument's bells and chimes are two
  sections. For a part with one section, a new "Page Break After One Chart"
  box decides.
- With separate charts, the message at the end of a run names any selected
  instrument that had nothing to chart.
- Sibelius creates a part for each chart instrument the plug-in adds.
  Building or removing a chart now deletes any part holding nothing but
  chart staves.
- P&F and Whitechapel handbells are charted as instruments of their own,
  after the SMBs, each on a treble and a bass staff and labelled
  `P&F Handbells Used: 6` and `Whitechapel Handbells Used: 4`. Each has a
  notehead box and a colour field in the dialog. As with SMBs, the notehead
  boxes open on `(no notehead)` until one is picked, and the last choice is
  remembered. The charts use the plain stemless handbell head, in the
  instrument's own colour when one is set.

### Fixed

- Ticking "Remove Existing Chart" did nothing, and a run with it ticked drew
  the chart again. A ticked checkbox hands back `true`, and the plug-in only
  counted `1` as ticked.
- When the chart and the first system of music did not fit on one page,
  they overlapped instead of the music moving on to the next page. Each
  chart bar ended with a break that Sibelius allows only in the middle of a
  page. It now ends with an ordinary system break.
- A chart's ledger lines could run into the system above or below it.
  Sibelius's Optimize Staff Spacing now runs over the chart and the first
  system of music in the full score, and over the chart in each part given
  one.
- The chart makes the start of the music a new section, so a score set to
  show no instrument names at new sections lost the names on its first
  system of music. While a chart is in place, the new-section option
  follows the first system's, and so does every other section start in the
  piece. Removing the chart puts the score's own setting back, and so does
  a removal that stops because the chart can no longer be identified.
- Removing a chart reset the full score's title block to its styles'
  default positions, so positioning done by hand was lost, including a
  title placed partly off the top of the page. The title block now keeps
  its positions.
- A copyright line set in a blank-page text style was moved from the first
  page down to the music, as if it were a tempo mark, and landed on top of
  it. Text in blank-page styles now stays on the first page with the title
  block.

### Changed

- The plug-in charts the full score even when it is run from a part, and
  returns to that part afterwards.
- The defaults are every instrument, one combined chart and no parts, so a
  first run charts the same sections, under the same labels, as 1.2.0.
- The dialog is wider and set out in two columns. The notehead boxes, the
  colour fields and "Remove Existing Chart" are on the right.

## [1.2.0] - 2026-08-23

Silver melody bells are charted as a third instrument, and the handchime
and SMB colour fields work for the first time.

### Added

- Silver melody bells are charted as a third instrument, with their own
  notehead dropdown, their own colour field and an `SMBs Used: n` section
  after the handbells and handchimes. The dropdown opens on `(no notehead)`,
  because nothing in a score suggests which head means an SMB, so a score
  without them charts exactly as it did.
- SMB columns are drawn with a `Square (stemless)` notehead, made by hand
  the way `Diamond (stemless)` is; the readme says how. Without it they fall
  back to shaped note 6, Sibelius' own square, written as whole notes to
  lose the stems, exactly as handchimes fall back to the built-in diamond.
  The run says so and names the notehead to make.

### Fixed

- Handchime and SMB colours had no effect, leaving both sections black. The
  colour components were written on each Note; a BarObject's colour can only
  be written while the object is selected, and a freshly added chart note
  never is, so the writes were silently discarded. Colour is now set on the
  NoteRest while it is selected, alpha included.
- Setting a handchime or SMB colour took the run down. `HexDigit` called a
  bare `LowerCase`, and no global of that name exists: it is
  `utils.LowerCase`. The colour path had never been exercised, so nothing
  had run into it. Both `LowerCase` and `UpperCase` had been listed as
  built-ins in the linter, which is what let the call ship; they are gone
  from that list, and the colour conversion has tests of its own.

### Changed

- A missing `Diamond (stemless)` is now reported the way a missing
  `Square (stemless)` is. Handchimes have always fallen back to hollow whole
  notes without saying so, which left the two instruments inconsistent and
  the fallback easy to mistake for the intended look. The warning names the
  instrument and the notehead to make.

### Removed

- The handbell and handchime label fields. The labels are generated, and
  they are ordinary staff text once the chart is drawn, so anyone wanting
  different wording can retype it in the score rather than filling in a
  dialog field on every run.

## [1.1.0] - 2026-08-23

The noteheads that mean handbells and handchimes are now yours to choose,
and the dialog's settings take effect for the first time.

### Added

- Handbell and handchime noteheads are now chosen in the dialog, from the
  noteheads the open score actually uses. Reported by a tester whose chimes
  carried a notehead other than the diamond the plugin used to insist on,
  and whose chimes therefore charted as nothing at all. Both dropdowns are
  filled from the score each time the dialog opens, and both offer a
  `(no notehead)` entry for a piece that has no such instrument in it.
- The dialog opens on the score's plain notehead for handbells and its
  diamond for handchimes, matching what the plugin assumed before, so a
  score that charted correctly still charts correctly untouched. The
  defaults are found by notehead index rather than by name, so a localised
  Sibelius picks them out too.
- The unrecognised-notehead warning names the heads it skipped, rather than
  only counting the notes. The names it prints are the ones the dropdowns
  offer, so the warning now says which entry to pick.

### Fixed

- None of the dialog's settings had ever taken effect. A control's ID and
  the variable storing its value are two separate properties, and only the
  ID was set, so every control read back whatever the plugin had written
  before opening the dialog. The handbell label, handchime label, handchime
  colour and remove-existing-chart checkbox have therefore done nothing
  since 1.0.0; all six controls are now bound.

### Changed

- The scan that fills the dropdowns skips an existing chart's own staves, so
  re-running never offers the chart's noteheads back as if the music used
  them.
- Choosing the same notehead for both instruments is refused with an
  explanation, before any existing chart is removed.

## [1.0.1] - 2026-08-23

Documentation and comments. No behaviour change: the plug-in does exactly
what 1.0.0 did, and only the comments carried inside it differ.

### Fixed

- Installation now gives the Windows plugin folder as well as the macOS
  one, and notes that the subfolder name is the category the plugin appears
  under in the Plug-ins gallery.
- Dropped the claim that the plugin is macOS-only. Nothing in the
  ManuScript is platform-specific; it is only untested on Windows, which
  the limitations now say instead. `npm run deploy` remains macOS-only, and
  its refusal message names the folder to copy into by hand.

### Changed

- A wording pass over the readme and the source comments, mostly replacing
  em dashes that had become a tic. Method bodies are copied into the `.plg`
  verbatim, so the rebuilt plug-in carries the reworded comments.

## [1.0.0] - 2026-08-23

First release. Verified against Sibelius Ultimate 2026 on macOS.

### Added

- Bell-name pitch space: conversion between Sibelius's written pitch and
  diatonic values and a bell's sounding pitch, correcting for the octave
  Sibelius has no transposing handbell instrument to apply itself.
- Bell naming and chart region assignment from a note's diatonic pitch.
- Collection of distinct bells and handchimes from a score's note records,
  honouring enharmonic spellings and diamond noteheads.
- Column stacking that groups octave-related bells into a shared column.
- Chart plan assembly, including warnings for out-of-range bells,
  unrecognised noteheads and unreadable pitches.
- A hidden marker written into the chart that lets a later run identify and
  replace or remove a chart this plugin made, and that refuses to touch
  anything it cannot positively identify.
- Reading note records from the open score, drawing the chart into it, and
  removing it again.
- A settings dialog (bell label, chime label, chime colour, remove existing
  chart), captured from Sibelius's own dialog editor into `src/Settings.msd`
  and emitted into the plug-in byte for byte.
- Stemless chart noteheads. Handbells use Sibelius's built-in `Stemless`
  notehead; handchimes look up a user-made `Diamond (stemless)` notehead by
  name, and fall back to whole notes, which carry no stem at any notehead
  style, when the score has none. See the README.
- The piece keeps its own bar numbering: the chart bars do not increment it
  and show no numbers of their own.
- Time signatures, key signatures and padding rests are suppressed across
  the chart bars, and the chart staves take an atonal key of their own so
  the piece's staves keep theirs.
- Musical directions such as tempo marks move to the first music bar rather
  than sitting over the chart, while the title block stays above it.
- An in-Sibelius automated test suite (`HandbellsUsedChartTests.plg`),
  passing 109 of 109 assertions.
- Build, lint, deploy and packaging tooling (`npm run build`, `npm run
  lint`, `npm run deploy`, `npm run package`) with no runtime or build-time
  dependencies, and a CI workflow that builds and lints on every pull
  request.

### Known limitations

- Removing a chart returns the score's title block to Sibelius's default
  positions for those text styles. Its content, styling and visibility
  survive; hand positioning does not. Building a chart never touches it.
- The gap between the title block and the chart is whatever Sibelius's
  automatic spacing gives it. ManuScript exposes no chart-scoped control
  over vertical spacing.

