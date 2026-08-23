# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

