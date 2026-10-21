TestReadScore() {
    score = Sibelius.ActiveScore;
    if (score = null) {
        AssertTrue(False, 'open a score before running the integration tests');
        return False;
    }

    records = ReadScoreNotes(score);
    AssertTrue(records.Length > 0, 'read at least one note from the open score');

    // Every record is in bell space, so nothing may be below C2 as a bell
    // unless the score really contains such a pitch.
    ok = True;
    for i = 0 to records.Length {
        // Not `= null`: ManuScript reads a real 0 as null, and a diatonic of 0
        // is a legitimate value, so a null test would fail a valid record.
        record = records[i];
        if (not(utils.IsNumeric('' & record.pitch, True))) {
            ok = False;
        }
        if (not(utils.IsNumeric('' & record.diatonic, True))) {
            ok = False;
        }
        if (not(utils.IsNumeric('' & record.staff, True))) {
            ok = False;
        }
    }
    AssertTrue(ok, 'every record carries a pitch, a diatonic pitch and a staff');
}

TestScoreInstruments() {
    score = Sibelius.ActiveScore;
    if (score = null) {
        AssertTrue(False, 'open a score before running the integration tests');
        return False;
    }

    // A chart left by an earlier run is not one of the piece's instruments,
    // and the last instrument has to end at the score's last staff.
    RemoveChart(score);

    instruments = ScoreInstruments(score);
    // Traced before asserting: the grouping rests on NumStavesInSameInstrument,
    // which the reference describes as the default instrument's stave count,
    // so a wrong grouping is something to see, not just to count.
    for i = 0 to instruments.Length {
        instrument = instruments[i];
        trace('[instrument] ' & instrument.name & ' ' & instrument.firstStaff
            & '-' & instrument.lastStaff);
    }
    AssertTrue(instruments.Length > 0, 'the score has at least one instrument');
    if (instruments.Length = 0) {
        return False;
    }

    first = instruments[0];
    AssertEquals(first.firstStaff, 1, 'the first instrument starts at staff 1');
    contiguous = True;
    for i = 1 to instruments.Length {
        before = instruments[i - 1];
        after = instruments[i];
        if (after.firstStaff != (before.lastStaff + 1)) {
            contiguous = False;
        }
    }
    AssertTrue(contiguous, 'instruments cover the staves without gaps');
    last = instruments[instruments.Length - 1];
    AssertEquals(last.lastStaff, score.StaffCount, 'instruments reach the last staff');
}

TestBuildChart() {
    score = Sibelius.ActiveScore;
    if (score = null) {
        AssertTrue(False, 'open a score before running the integration tests');
        return False;
    }

    // The tests run on whatever score is open, which may already carry a chart
    // from a real run. BuildChart does not clear one first - ChartScore does
    // that - so building here would stack a second chart, leaving two markers.
    // TestRemoveChart would then remove one and still find the other, which is
    // what 'marker gone' and 'second removal finds no chart' were reporting.
    RemoveChart(score);

    staffCountBefore = score.StaffCount;
    barCountBefore = score.NthStaff(1).BarCount;
    firstPageBefore = FirstPageTextCount(score);

    records = ReadScoreNotes(score);
    choices = ScoreHeadChoices(score);
    // Every instrument, combined: the defaults a first run opens on, which
    // chart the same sections under the same labels v1.2.0 did.
    options = IntegrationOptions(choices, ScoreInstruments(score), 'combined', False, False);
    plan = BuildChartPlan(records, options);
    result = BuildChart(score, plan, options);

    AssertTrue(result.ok, 'build reported success: ' & result.error);
    // A score with no SMB section cannot want the square notehead, so nothing
    // should be warning about one.
    AssertEquals(result.warnings.Length, 0, 'a chart with no SMBs warns about nothing');
    AssertEquals(score.StaffCount, staffCountBefore + (plan.sections.Length * 2),
        'two staves added per section');
    AssertEquals(score.NthStaff(1).BarCount, barCountBefore + plan.sections.Length,
        'one bar added per section');
    AssertTrue(MarkerFind(score) != null, 'marker written');

    // The first chart bar is as long as its column count.
    expected = plan.sections[0].columns * 256;
    AssertEquals(score.NthStaff(1).NthBar(1).Length, expected, 'chart bar length');

    // The chart contributes nothing to the piece's numbering, so the first
    // music bar is still bar 1 however many sections sit in front of it.
    firstMusic = score.NthStaff(1).NthBar(plan.sections.Length + 1);
    AssertEquals('' & firstMusic.ExternalBarNumberString, '1',
        'the piece still starts at bar 1');

    // A system break that may also end a page. EndOfSystem forbids the end of
    // a page, which forced every chart system and the first music system onto
    // one page, overlapping wherever they did not fit.
    breaks = 1;
    for i = 0 to plan.sections.Length {
        if (score.NthStaff(1).NthBar(i + 1).BreakType != EndOfSystemOrPage) {
            breaks = 0;
        }
    }
    AssertEquals(breaks, 1, 'every chart bar ends with a break that may end a page');

    // The music's first system starts a new section, and takes the names the
    // score's first system would have had.
    rules = score.EngravingRules;
    AssertEquals(rules.InstrumentNamesNewSections, rules.InstrumentNamesFirstSystem,
        'the music starts with the names the first system would have had');
    AssertEquals(FirstPageTextCount(score), firstPageBefore,
        'the title block and blank-page text stay in the first bar');

    // The dialog is filled before a re-run removes the chart, so the chart's
    // own staves must not be offered as one of the piece's instruments.
    offered = ScoreInstruments(score);
    lastOffered = offered[offered.Length - 1];
    AssertEquals(lastOffered.lastStaff, staffCountBefore, 'the chart is not offered as an instrument');

    // A plan the parts were never planned for copies nothing onto the piece's
    // own staves and has nothing to restore.
    AssertEquals(NotesInBar(score.NthStaff(1).NthBar(1)), 0, 'a build without parts draws no copies');
    restores = RestoreMarkerRead(score, staffCountBefore + 1);
    AssertEquals(restores.Length, 0, 'and records no restores');
}

// How many NoteRests in a bar hold notes.
NotesInBar(bar) {
    count = 0;
    for each NoteRest nr in bar {
        if (nr.NoteCount > 0) {
            count = count + 1;
        }
    }
    return count;
}

// How many text items in the first bar belong to the first page rather than
// to the music.
FirstPageTextCount(score) {
    count = 0;
    firstBar = score.SystemStaff.NthBar(1);
    for each item in firstBar {
        if (item.Type = 'SystemTextItem') {
            if (StyleStaysOnFirstPage(item.StyleId)) {
                count = count + 1;
            }
        }
    }
    return count;
}

TestRemoveChart() {
    score = Sibelius.ActiveScore;
    if (score = null) {
        AssertTrue(False, 'open a score before running the integration tests');
        return False;
    }

    // Runs after TestBuildChart, so a chart is present.
    found = FindChart(score);
    AssertTrue(found.found, 'chart identified: ' & found.error);

    staffCountBefore = score.StaffCount;
    barCountBefore = score.NthStaff(1).BarCount;
    sections = found.sections;
    parts = score.DynamicParts;
    titleBefore = PartTitleText(score, parts[0]);

    result = RemoveChart(score);
    AssertTrue(result.removed, 'chart removed: ' & result.error);
    AssertEquals(score.StaffCount, staffCountBefore - (sections * 2), 'chart staves gone');
    AssertEquals(score.NthStaff(1).BarCount, barCountBefore - sections, 'chart bars gone');
    AssertEquals(MarkerFind(score), null, 'marker gone');
    // The title block hangs from the first system's top staff in whichever
    // bar holds it, so its offsets mean on the music what they meant on the
    // chart, even where they put a line off the page.
    AssertEquals(PartTitleText(score, parts[0]), titleBefore, 'the full score keeps its title block where it was');

    // A second removal finds nothing and says so without erroring.
    again = RemoveChart(score);
    AssertEquals(again.removed, False, 'second removal finds no chart');
    AssertEquals(again.error, '', 'no chart is not an error');
}

// The names rule round trip, from a setting known to differ from the first
// system's, so that both halves can fail: a build that leaves it alone, and a
// removal that does not put it back.
TestNamesRule() {
    score = Sibelius.ActiveScore;
    if (score = null) {
        AssertTrue(False, 'open a score before running the integration tests');
        return False;
    }

    RemoveChart(score);
    rules = score.EngravingRules;
    own = rules.InstrumentNamesNewSections;
    differing = 0;
    if (rules.InstrumentNamesFirstSystem = 0) {
        differing = 1;
    }
    rules.InstrumentNamesNewSections = differing;

    choices = ScoreHeadChoices(score);
    options = IntegrationOptions(choices, ScoreInstruments(score), 'combined', False, False);
    plan = BuildChartPlan(ReadScoreNotes(score), options);
    built = BuildChart(score, plan, options);
    AssertTrue(built.ok, 'the names fixture builds: ' & built.error);
    rules = score.EngravingRules;
    AssertEquals(rules.InstrumentNamesNewSections, rules.InstrumentNamesFirstSystem,
        'while a chart is in place the music is named as the first system is');

    RemoveChart(score);
    rules = score.EngravingRules;
    AssertEquals(rules.InstrumentNamesNewSections, differing,
        'removing the chart puts back the setting the score had');
    rules.InstrumentNamesNewSections = own;
}

TestBuildSeparate() {
    score = Sibelius.ActiveScore;
    if (score = null) {
        AssertTrue(False, 'open a score before running the integration tests');
        return False;
    }

    RemoveChart(score);
    instruments = ScoreInstruments(score);
    if (instruments.Length < 2) {
        AssertTrue(False, 'fixture: needs two instruments with notes');
        return False;
    }

    staffCountBefore = score.StaffCount;
    choices = ScoreHeadChoices(score);
    options = IntegrationOptions(choices, instruments, 'separate', False, False);
    plan = BuildChartPlan(ReadScoreNotes(score), options);
    AssertTrue(plan.sections.Length > 0, 'the fixture charts something');
    if (plan.sections.Length = 0) {
        return False;
    }

    result = BuildChart(score, plan, options);
    AssertTrue(result.ok, 'separate build reported success: ' & result.error);
    sections = plan.sections.Length;
    AssertEquals(score.StaffCount, staffCountBefore + (sections * 2), 'two staves added per section, separately');

    // The chart staves go at the bottom, so the first one follows the piece.
    firstSection = plan.sections[0];
    trebleBar = score.NthStaff(staffCountBefore + 1).NthBar(1);
    labelled = False;
    for each Text t in trebleBar {
        if (('' & t.Text) = firstSection.label) {
            labelled = True;
        }
    }
    AssertTrue(labelled, 'the first chart is labelled with its instrument name');

    removal = RemoveChart(score);
    AssertTrue(removal.removed, 'separate chart removed: ' & removal.error);
}

TestEnterFullScore() {
    score = Sibelius.ActiveScore;
    if (score = null) {
        AssertTrue(False, 'open a score before running the integration tests');
        return False;
    }

    part = PartHoldingStaff(score, 1);
    if (part = null) {
        AssertTrue(False, 'fixture: staff 1 needs a part');
        return False;
    }

    score.CurrentDynamicPart = part;
    was = EnterFullScore(score);
    current = score.CurrentDynamicPart;
    AssertEquals(current.IsFullScore, True, 'charting happens in the full score');
    AssertEquals(was.IsFullScore, False, 'the part view is what gets restored');
    score.CurrentDynamicPart = was;
    EnterFullScore(score);
}

TestBuildChartParts() {
    score = Sibelius.ActiveScore;
    if (score = null) {
        AssertTrue(False, 'open a score before running the integration tests');
        return False;
    }

    RemoveChart(score);
    instruments = ScoreInstruments(score);
    if (instruments.Length < 2) {
        AssertTrue(False, 'fixture: needs two instruments with parts of their own');
        return False;
    }
    first = instruments[0];
    second = instruments[1];
    partA = PartHoldingStaff(score, first.firstStaff);
    partB = PartHoldingStaff(score, second.firstStaff);
    if ((partA = null) or (partB = null)) {
        AssertTrue(False, 'fixture: needs two instruments with parts of their own');
        return False;
    }
    if (partA.IncludesStaff(score.NthStaff(second.firstStaff))) {
        AssertTrue(False, 'fixture: the first two instruments need a part each, not one between them');
        return False;
    }

    // Every part's title block and page layout before any chart, and the first
    // instrument's key and clef where it starts. A run with parts must leave
    // the parts' title blocks alone, and a removal must leave every part, and
    // the staves that held copies, exactly as they began.
    parts = score.DynamicParts;
    keyBefore = score.NthStaff(first.firstStaff).CurrentKeySignature(1).Sharps;
    fullTitle = PartTitleText(score, parts[0]);
    titlesBefore = AllPartTitles(score);
    layoutsBefore = AllPartLayouts(score);
    furnitureBefore = InstrumentFurniture(score, first);

    // Both plans from the clean score: once a chart is drawn, reading the
    // score again would read the chart's own notes back in. The labels a
    // section gets in the parts are decided by planning the parts, which only
    // reads them, so the expected plan is planned the same way.
    choices = ScoreHeadChoices(score);
    records = ReadScoreNotes(score);
    oldOptions = IntegrationOptions(choices, instruments, 'combined', False, False);
    newOptions = IntegrationOptions(choices, instruments, 'separate', True, False);
    oldShape = BuildChartPlan(records, oldOptions);
    expected = BuildChartPlan(records, newOptions);
    planned = PlanParts(score, expected, newOptions);

    partsBefore = parts.NumChildren;
    staveCountsBefore = PartStaveCounts(score);

    // What a full-score build alone leaves in a part, to compare against: a
    // run without parts must leave every part exactly as that.
    BuildChart(score, oldShape, oldOptions);
    plainHidden = HiddenStavesInPart(score, partA, 1);
    ChartScore(score, IntegrationOptions(choices, instruments, 'combined', False, True));

    // A combined chart without parts, then a real re-run over it with every
    // new option on, which removes the old chart itself.
    built = DrawCharts(score, oldShape, oldOptions);
    AssertTrue(built.ok, 'the combined chart is drawn: ' & built.error);
    AssertEquals(HiddenStavesInPart(score, partA, 1), plainHidden,
        'a run without parts leaves the parts as a full-score build does');
    rebuilt = ChartScore(score, newOptions);
    AssertTrue(rebuilt.ok, 'the separate chart with parts replaces the combined one: ' & rebuilt.text);
    found = FindChart(score);
    AssertEquals(found.sections, expected.sections.Length, 'the re-run chart has every section');
    // The dialog reads the score's noteheads before a re-run removes the
    // chart, and the parts' copies sit on the music's own staves in the chart
    // bars, drawn in the chart's heads.
    offered = ScoreHeadChoices(score);
    AssertEquals(JoinNames(offered.names), JoinNames(choices.names),
        'a re-run offers the noteheads of the music alone');
    skipped = planned.skipped;
    if (skipped.Length > 0) {
        AssertTrue(TextContains(rebuilt.text, 'No chart was added to the parts for'),
            'the run names the instruments whose staves cannot hold a copy');
    }

    // The first instrument's copy of its first chart, on its own staves: shown
    // in its part and not in the full score, where those staves stay hidden
    // through every chart bar. The music keeps its key where it starts.
    fullScore = parts[0];
    chartBars = expected.sections.Length;
    copyBar = 0;
    copyStaff = 0;
    copyLabel = '';
    for i = 0 to chartBars {
        section = expected.sections[i];
        copyOwners = section.copyOwners;
        for j = 0 to copyOwners.Length {
            if (copyBar = 0) {
                if (copyOwners[j] = first.name) {
                    copies = section.copies;
                    staves = copies[j];
                    copyBar = i + 1;
                    copyStaff = staves[0];
                    copyLabel = section.label;
                    if (section.splitLabel = 1) {
                        copyLabel = section.plainLabel;
                    }
                }
            }
        }
    }
    if (copyBar = 0) {
        AssertTrue(False, 'fixture: the first instrument needs a chart its staves can hold');
    } else {
        AssertEquals(CopyState(score, fullScore, copyStaff, copyBar), 'hidden',
            'the full score does not show the copy');
        AssertEquals(CopyState(score, partA, copyStaff, copyBar), 'shown', 'the first part shows its copy');
        AssertEquals(TextHiddenIn(score, fullScore, copyStaff, copyBar, copyLabel), 1,
            'the full score hides the copy label');
        AssertEquals(TextHiddenIn(score, partA, copyStaff, copyBar, copyLabel), 0,
            'the first part shows the copy label');
        shownInScore = 0;
        for b = 1 to chartBars + 1 {
            scoreFlags = PartHiddenFlags(score, fullScore, b);
            if (scoreFlags[copyStaff - 1] != 1) {
                shownInScore = shownInScore + 1;
            }
        }
        AssertEquals(shownInScore, 0, 'the full score hides the copy staves in every chart bar');
        AssertEquals(score.NthStaff(first.firstStaff).CurrentKeySignature(chartBars + 1).Sharps, keyBefore,
            'the first instrument keeps its key where the music starts');
    }

    // Adding a staff to a part resets its title block and staff spacing, so a
    // part shows its charts on copies and never gains or loses a staff.
    AssertEquals(PartStaveCounts(score), staveCountsBefore, 'no part gains or loses a staff');
    AssertEquals(parts.NumChildren, partsBefore, 'no chart-only parts are left behind');
    AssertEquals(AllPartTitles(score), titlesBefore, 'every part keeps its title block through a run');
    carriedA = PartSections(expected.sections, CreateSparseArray(first.name));
    wanted = EndOfSystemOrPage;
    if (PartEndsPage(carriedA.Length, False) = 1) {
        wanted = EndOfPage;
    }
    AssertEquals(PartBarBreak(score, partA, expected.sections.Length), wanted,
        'the first part ends its charts with a page break only when it should');

    // Every chart bar in the part shows the staves holding its own chart's copy
    // and nothing else.
    systemsA = PartChartSystems(CarriedPositions(chartBars, carriedA));
    staffNumsA = PartStaffNumbers(partA);
    showsA = systemsA.shows;
    layoutDetail = '';
    for b = 1 to chartBars + 1 {
        position = showsA[b - 1];
        index = carriedA[position];
        shown = expected.sections[index];
        wantedHidden = JoinNames(PartBarHiddenStaves(staffNumsA, SectionCopyStaves(shown)));
        gotHidden = JoinNames(PartHiddenFlags(score, partA, b));
        if (gotHidden != wantedHidden) {
            layoutDetail = layoutDetail & ((' bar ' & b) & (' wanted ' & wantedHidden) & (' got ' & gotHidden));
        }
    }
    AssertEquals(layoutDetail, '', 'each chart bar in the first part shows only its own chart');

    // A run that would chart nothing is refused before the chart is touched.
    refused = ChartScore(score, IntegrationOptions(choices, CreateSparseArray(), 'separate', True, False));
    AssertTrue(not(refused.ok), 'a run with no instrument selected is refused');
    kept = FindChart(score);
    AssertTrue(kept.found, 'and the chart it refused to replace is still there');

    removal = ChartScore(score, IntegrationOptions(choices, instruments, 'separate', True, True));
    AssertTrue(removal.ok, 'the chart with parts is removed: ' & removal.text);
    AssertEquals(PartStaveCounts(score), staveCountsBefore, 'removal leaves every part its own staves');
    AssertEquals(parts.NumChildren, partsBefore, 'removal leaves the parts as they were');
    AssertEquals(PartTitleText(score, parts[0]), fullTitle, 'the full score title block is where it started');
    AssertEquals(AllPartTitles(score), titlesBefore, 'every part title block is where it started');
    AssertEquals(AllPartLayouts(score), layoutsBefore, 'every part has the pages and systems it started with');
    AssertEquals(InstrumentFurniture(score, first), furnitureBefore,
        'the first instrument has its own key and clef back and nothing added');
}

// The open score given a key with sharps, and its own key put back after.
// Without parts the chart staves take a hidden no-key change of their own and
// the music keeps its key. With parts the chart bars take C major for the
// copies, and the music starts with its key as an ordinary key change, which
// a removal leaves as the music's opening key.
TestBuildKeyed() {
    score = Sibelius.ActiveScore;
    if (score = null) {
        AssertTrue(False, 'open a score before running the integration tests');
        return False;
    }

    RemoveChart(score);
    own = score.NthStaff(1).CurrentKeySignature(1);
    ownSharps = own.Sharps;
    ownMajor = own.Major;
    score.NthStaff(1).NthBar(1).AddKeySignature(0, 2, True, False, False, False);
    pieceStaves = score.StaffCount;
    keysBefore = StaffKeys(score, pieceStaves, 1);
    choices = ScoreHeadChoices(score);
    records = ReadScoreNotes(score);
    instruments = ScoreInstruments(score);

    plain = ChartScore(score, IntegrationOptions(choices, instruments, 'combined', False, False));
    AssertTrue(plain.ok, 'a score in a key is charted: ' & plain.text);
    found = FindChart(score);
    AssertEquals(score.NthStaff(pieceStaves + 1).CurrentKeySignature(1).Sharps, -8,
        'the chart is drawn with no key');
    AssertEquals(StaffKeys(score, pieceStaves, found.sections + 1), keysBefore,
        'without parts the music starts in its key');
    RemoveChart(score);
    AssertEquals(StaffKeys(score, pieceStaves, 1), keysBefore, 'a removal leaves the music its key');

    options = IntegrationOptions(choices, instruments, 'separate', True, False);
    plan = BuildChartPlan(records, options);
    PlanParts(score, plan, options);
    sections = plan.sections;
    copyBar = 0;
    copyStaff = 0;
    for i = 0 to sections.Length {
        section = sections[i];
        copies = section._property:copies;
        if (copies != null) {
            if ((copyBar = 0) and (copies.Length > 0)) {
                staves = copies[0];
                copyBar = i + 1;
                copyStaff = staves[0];
            }
        }
    }
    withParts = ChartScore(score, options);
    AssertTrue(withParts.ok, 'a score in a key is charted with parts: ' & withParts.text);
    found = FindChart(score);
    if (copyBar = 0) {
        AssertTrue(False, 'fixture: needs an instrument whose staves can hold a copy');
    } else {
        AssertEquals(score.NthStaff(copyStaff).CurrentKeySignature(copyBar).Sharps, 0,
            'a copy is drawn in C major');
    }
    AssertEquals(StaffKeys(score, pieceStaves, found.sections + 1), keysBefore,
        'with parts the music starts in its key');
    RemoveChart(score);
    AssertEquals(StaffKeys(score, pieceStaves, 1), keysBefore,
        'a removal with parts leaves the music its key');

    score.NthStaff(1).NthBar(1).AddKeySignature(0, ownSharps, ownMajor, False, False, False);
    return True;
}

// Each of the first count staves' key at the given bar, in sharps.
StaffKeys(score, count, barNum) {
    keys = CreateSparseArray();
    for n = 1 to count + 1 {
        keys.Push(score.NthStaff(n).CurrentKeySignature(barNum).Sharps);
    }
    return JoinNames(keys);
}

// The parts holding staves, other than the full score, collected before any
// is made current: the collection is not to be changed while it is walked.
StavedParts(score) {
    found = CreateSparseArray();
    parts = score.DynamicParts;
    for each part in parts {
        if (not(part.IsFullScore)) {
            if (part.StaveCount > 0) {
                found.Push(part);
            }
        }
    }
    return found;
}

// Every part's first-page text offsets, in part order, as one line.
AllPartTitles(score) {
    found = StavedParts(score);
    line = '';
    for i = 0 to found.Length {
        line = line & (('[' & PartTitleText(score, found[i])) & ']');
    }
    return line;
}

// Every part's page count and systems per page, in part order, as one line.
// Adding a staff to a part reset its staff spacing, which showed here first.
AllPartLayouts(score) {
    found = StavedParts(score);
    line = '';
    for i = 0 to found.Length {
        line = line & (('[' & PartLayout(score, found[i])) & ']');
    }
    return line;
}

PartLayout(score, part) {
    was = score.CurrentDynamicPart;
    score.CurrentDynamicPart = part;
    line = 'pages ' & score.PageCount;
    p = 1;
    while (p <= score.PageCount) {
        line = line & (' ' & score.SystemCount(p));
        p = p + 1;
    }
    score.CurrentDynamicPart = was;
    return line;
}

// An instrument's key and clef at its first bar, and how many key and clef
// objects that bar holds at its start, staff by staff.
InstrumentFurniture(score, instrument) {
    line = '';
    n = instrument.firstStaff;
    while (n <= instrument.lastStaff) {
        staff = score.NthStaff(n);
        bar = staff.NthBar(1);
        clef = bar.GetClefAt(0);
        keys = 0;
        for each KeySignature ks in bar {
            if (ks.Position = 0) {
                keys = keys + 1;
            }
        }
        clefs = 0;
        for each Clef c in bar {
            if (c.Position = 0) {
                clefs = clefs + 1;
            }
        }
        line = line & (('[key ' & staff.CurrentKeySignature(1).Sharps) & (' clef ' & clef.ConcertClefStyleId));
        line = line & ((' keys ' & keys) & ((' clefs ' & clefs) & ']'));
        n = n + 1;
    }
    return line;
}

// Every option ChartScore and the drawing read, for a test to vary the ones it
// is about.
IntegrationOptions(choices, instruments, mode, parts, remove) {
    return CreateDictionary('chimeColor', '', 'smbColor', '', 'pfColor', '', 'whitechapelColor', '',
        'bellHead', choices.defaultBell, 'chimeHead', choices.defaultChime,
        'smbHead', NoNoteHead(), 'pfHead', NoNoteHead(), 'whitechapelHead', NoNoteHead(),
        'instruments', instruments, 'mode', mode,
        'parts', parts, 'pageBreak', False, 'remove', remove);
}

// The first part, other than the full score, holding the given staff, or null
// when no part does.
PartHoldingStaff(score, staffNum) {
    staff = score.NthStaff(staffNum);
    parts = score.DynamicParts;
    for each part in parts {
        if (not(part.IsFullScore)) {
            if (part.IncludesStaff(staff)) {
                return part;
            }
        }
    }
    return null;
}

// A part's first-page top staff margin and whether its first page has margins
// of its own, read in the part.
// 1 when the text in a bar of a staff is hidden where the given part or the
// full score shows it, 0 when it is shown, -1 when there is no such text. The
// staff is found while the full score is current.
TextHiddenIn(score, part, staffNum, barNum, text) {
    bar = score.NthStaff(staffNum).NthBar(barNum);
    was = score.CurrentDynamicPart;
    score.CurrentDynamicPart = part;
    hidden = -1;
    for each Text t in bar {
        if (('' & t.Text) = text) {
            hidden = 0;
            if (t.Hidden) {
                hidden = 1;
            }
        }
    }
    score.CurrentDynamicPart = was;
    return hidden;
}

// The offsets of a part's first-page text, read in that part, as one line to
// compare.
PartTitleText(score, part) {
    was = score.CurrentDynamicPart;
    score.CurrentDynamicPart = part;
    line = '';
    firstBar = score.SystemStaff.NthBar(1);
    for each item in firstBar {
        if (item.Type = 'SystemTextItem') {
            if (StyleStaysOnFirstPage(item.StyleId)) {
                line = line & ((' ' & item.Dx) & (',' & item.Dy));
            }
        }
    }
    score.CurrentDynamicPart = was;
    return line;
}

// 'shown' or 'hidden' for the first NoteRest with notes in a bar of a staff,
// as the given part or the full score shows it, or 'none' when the bar has no
// notes. The staff is found while the full score is current.
CopyState(score, part, staffNum, barNum) {
    bar = score.NthStaff(staffNum).NthBar(barNum);
    was = score.CurrentDynamicPart;
    score.CurrentDynamicPart = part;
    state = 'none';
    for each NoteRest nr in bar {
        if (state = 'none') {
            if (nr.NoteCount > 0) {
                state = 'shown';
                if (nr.Hidden) {
                    state = 'hidden';
                }
            }
        }
    }
    score.CurrentDynamicPart = was;
    return state;
}

// Every part's staff count, in part order, as one line to compare.
PartStaveCounts(score) {
    line = '';
    parts = score.DynamicParts;
    for each part in parts {
        if (not(part.IsFullScore)) {
            line = line & (' ' & part.StaveCount);
        }
    }
    return line;
}

// A bar's break as one part sees it.
PartBarBreak(score, part, barNum) {
    was = score.CurrentDynamicPart;
    score.CurrentDynamicPart = part;
    breakType = score.NthStaff(1).NthBar(barNum).BreakType;
    score.CurrentDynamicPart = was;
    return breakType;
}

// How many of a part's staves are hidden in a bar.
HiddenStavesInPart(score, part, barNum) {
    flags = PartHiddenFlags(score, part, barNum);
    hidden = 0;
    for i = 0 to flags.Length {
        hidden = hidden + flags[i];
    }
    return hidden;
}

// Each of a part's staves in a bar, top to bottom, 1 when hidden, read in that
// part's own context, since hiding belongs to each part separately. The staves
// are found first, while the full score is current.
PartHiddenFlags(score, part, barNum) {
    staves = CreateSparseArray();
    for each staff in part {
        staves.Push(staff);
    }
    was = score.CurrentDynamicPart;
    score.CurrentDynamicPart = part;
    flags = CreateSparseArray();
    for i = 0 to staves.Length {
        staff = staves[i];
        flag = 0;
        if (staff.NthBar(barNum).OnHiddenStave) {
            flag = 1;
        }
        flags.Push(flag);
    }
    score.CurrentDynamicPart = was;
    return flags;
}

TestNoteHeadScan() {
    score = Sibelius.ActiveScore;
    if (score = null) {
        AssertTrue(False, 'open a score before running the integration tests');
        return False;
    }

    // The scan deliberately skips a chart's own staves, while ReadScoreNotes
    // reads every staff there is. Comparing the two on a score that still
    // carries a chart from an earlier run would fail on that difference rather
    // than on anything the scan got wrong, so the chart goes first.
    RemoveChart(score);

    choices = ScoreHeadChoices(score);
    AssertTrue(choices.names.Length > 0, 'the score offers at least one notehead');

    // Every head a note really carries has to be offered, or the dropdown
    // cannot name the notehead the user is looking at.
    records = ReadScoreNotes(score);
    offered = True;
    for i = 0 to records.Length {
        record = records[i];
        if (HeadListed(choices.names, record.head) = 0) {
            offered = False;
        }
    }
    AssertTrue(offered, 'every head a note carries is offered');

    seen = CreateDictionary();
    unique = True;
    for i = 0 to choices.names.Length {
        name = choices.names[i];
        if (seen[name] != null) {
            unique = False;
        }
        seen[name] = 1;
    }
    AssertTrue(unique, 'the offered heads are distinct');

    // The value the dialog opens on has to be one the dropdown can show, and
    // the dropdown shows the no-notehead entry as well as the score's heads.
    items = HeadChoiceItems(choices.names);
    AssertEquals(HeadListed(items, PreferredHead(choices.names, '', choices.defaultBell)), 1,
        'the bell default is one of the offered entries');
    AssertEquals(HeadListed(items, PreferredHead(choices.names, '', choices.defaultChime)), 1,
        'the chime default is one of the offered entries');
}
