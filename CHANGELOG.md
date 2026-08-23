# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
- Run orchestration tying the above together, plus the settings data (bell
  label, chime label, chime colour, remove existing chart) a settings
  dialog will read from and write back to.
- An in-Sibelius automated test suite (`HandbellsUsedChartTests.plg`),
  passing 83 of 83 assertions on Sibelius Ultimate 2026 (macOS).
- Build, lint and deploy tooling (`npm run build`, `npm run lint`,
  `npm run deploy`) with no runtime or build-time dependencies, and a CI
  workflow that builds and lints on every pull request.

Not yet included: `src/Settings.msd`, the settings dialog itself, captured
from Sibelius's own dialog editor. Until it exists, the main plugin cannot
be run — see the README's Status section.
