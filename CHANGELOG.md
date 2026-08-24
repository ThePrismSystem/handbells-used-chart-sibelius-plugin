# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

