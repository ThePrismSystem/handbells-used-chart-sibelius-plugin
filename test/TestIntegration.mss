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
    }
    AssertTrue(ok, 'every record carries a pitch and a diatonic pitch');
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

    records = ReadScoreNotes(score);
    choices = ScoreHeadChoices(score);
    options = CreateDictionary('bellLabel', '', 'chimeLabel', '', 'chimeColor', '',
        'bellHead', choices.defaultBell, 'chimeHead', choices.defaultChime);
    plan = BuildPlan(records, options);
    result = BuildChart(score, plan, options);

    AssertTrue(result.ok, 'build reported success: ' & result.error);
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

    result = RemoveChart(score);
    AssertTrue(result.removed, 'chart removed: ' & result.error);
    AssertEquals(score.StaffCount, staffCountBefore - (sections * 2), 'chart staves gone');
    AssertEquals(score.NthStaff(1).BarCount, barCountBefore - sections, 'chart bars gone');
    AssertEquals(MarkerFind(score), null, 'marker gone');

    // A second removal finds nothing and says so without erroring.
    again = RemoveChart(score);
    AssertEquals(again.removed, False, 'second removal finds no chart');
    AssertEquals(again.error, '', 'no chart is not an error');
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
