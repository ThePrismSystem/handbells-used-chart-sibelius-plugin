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
    // Every instrument, combined: the defaults a first run opens on, and so
    // the proof that they still draw exactly what v1.2.0 drew.
    options = CreateDictionary('chimeColor', '', 'smbColor', '',
        'bellHead', choices.defaultBell, 'chimeHead', choices.defaultChime,
        'smbHead', NoNoteHead(),
        'instruments', ScoreInstruments(score), 'mode', 'combined');
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
    rules = score.EngravingRules;
    namesAfter = rules.InstrumentNamesNewSections;
    kept = NamesMarkerRead(score, found.firstStaff);
    if (kept >= 0) {
        namesAfter = kept;
    }

    result = RemoveChart(score);
    AssertTrue(result.removed, 'chart removed: ' & result.error);
    AssertEquals(score.StaffCount, staffCountBefore - (sections * 2), 'chart staves gone');
    AssertEquals(score.NthStaff(1).BarCount, barCountBefore - sections, 'chart bars gone');
    AssertEquals(MarkerFind(score), null, 'marker gone');
    AssertEquals(rules.InstrumentNamesNewSections, namesAfter, 'the score gets its own names rule back');

    // A second removal finds nothing and says so without erroring.
    again = RemoveChart(score);
    AssertEquals(again.removed, False, 'second removal finds no chart');
    AssertEquals(again.error, '', 'no chart is not an error');
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
    options = CreateDictionary('chimeColor', '', 'smbColor', '',
        'bellHead', choices.defaultBell, 'chimeHead', choices.defaultChime,
        'smbHead', NoNoteHead(), 'instruments', instruments, 'mode', 'separate');
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

    // Both plans from the clean score: once a chart is drawn, reading the
    // score again would read the chart's own notes back in.
    choices = ScoreHeadChoices(score);
    records = ReadScoreNotes(score);
    oldOptions = CreateDictionary('chimeColor', '', 'smbColor', '',
        'bellHead', choices.defaultBell, 'chimeHead', choices.defaultChime,
        'smbHead', NoNoteHead(), 'instruments', instruments, 'mode', 'combined', 'parts', False);
    newOptions = CreateDictionary('chimeColor', '', 'smbColor', '',
        'bellHead', choices.defaultBell, 'chimeHead', choices.defaultChime,
        'smbHead', NoNoteHead(), 'instruments', instruments, 'mode', 'separate', 'parts', True);
    oldShape = BuildChartPlan(records, oldOptions);
    expected = BuildChartPlan(records, newOptions);

    parts = score.DynamicParts;
    partsBefore = parts.NumChildren;
    stavesA = partA.StaveCount;
    stavesB = partB.StaveCount;

    // What a full-score build alone leaves in a part, to compare against: a
    // run without parts must leave every part exactly as that.
    BuildChart(score, oldShape, oldOptions);
    plainHidden = HiddenStavesInPart(score, partA, 1);
    RemoveChart(score);

    // The shape v1.2.0 draws, then a re-run over it with every new option on.
    built = DrawCharts(score, oldShape, oldOptions);
    AssertTrue(built.ok, 'the combined chart is drawn: ' & built.error);
    AssertEquals(HiddenStavesInPart(score, partA, 1), plainHidden,
        'a run without parts leaves the parts as 1.2.0 did');
    RemoveChart(score);
    titleA = PartTitleText(score, partA);
    rebuilt = DrawCharts(score, expected, newOptions);
    AssertTrue(rebuilt.ok, 'the separate chart with parts is drawn over it: ' & rebuilt.error);
    found = FindChart(score);
    AssertEquals(found.sections, expected.sections.Length, 'the re-run chart has every section');

    onlyOwnA = True;
    onlyOwnB = True;
    for i = 0 to expected.sections.Length {
        section = expected.sections[i];
        treble = score.NthStaff(found.firstStaff + (i * 2));
        inA = 0;
        if (partA.IncludesStaff(treble)) {
            inA = 1;
        }
        inB = 0;
        if (partB.IncludesStaff(treble)) {
            inB = 1;
        }
        if (inA != HeadListed(section.owners, first.name)) {
            onlyOwnA = False;
        }
        if (inB != HeadListed(section.owners, second.name)) {
            onlyOwnB = False;
        }
    }
    AssertTrue(onlyOwnA, 'the first part carries its own charts and no others');
    AssertTrue(onlyOwnB, 'the second part carries its own charts and no others');
    AssertEquals(parts.NumChildren, partsBefore, 'no chart-only parts are left behind');
    AssertEquals(PartTitleText(score, partA), titleA, 'the first part keeps its title block where it was');

    removal = RemoveChart(score);
    AssertTrue(removal.removed, 'the chart with parts is removed: ' & removal.error);
    AssertEquals(partA.StaveCount, stavesA, 'the chart staves leave the first part with the chart');
    AssertEquals(partB.StaveCount, stavesB, 'the chart staves leave the second part with the chart');
    AssertEquals(parts.NumChildren, partsBefore, 'removal leaves the parts as they were');
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

// How many of a part's staves are hidden in a bar, read in that part's own
// context, since hiding belongs to each part separately. The staves are found
// first, while the full score is current.
HiddenStavesInPart(score, part, barNum) {
    staves = CreateSparseArray();
    for each staff in part {
        staves.Push(staff);
    }
    was = score.CurrentDynamicPart;
    score.CurrentDynamicPart = part;
    hidden = 0;
    for i = 0 to staves.Length {
        staff = staves[i];
        if (staff.NthBar(barNum).OnHiddenStave) {
            hidden = hidden + 1;
        }
    }
    score.CurrentDynamicPart = was;
    return hidden;
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
