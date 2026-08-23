TestReadScore() {
    score = Sibelius.ActiveScore;
    if (score = null) {
        AssertTrue(False, 'open a score before running the integration tests');
        return False;
    }

    records = ReadScoreNotes(score, 0);
    AssertTrue(records.Length > 0, 'read at least one note from the open score');

    // Every record is in bell space, so nothing may be below C2 as a bell
    // unless the score really contains such a pitch.
    ok = True;
    for i = 0 to records.Length {
        if ((records[i].pitch = null) or (records[i].diatonic = null)) {
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

    staffCountBefore = score.StaffCount;
    barCountBefore = score.NthStaff(1).BarCount;

    records = ReadScoreNotes(score, 0);
    options = CreateDictionary('bellLabel', '', 'chimeLabel', '', 'chimeColor', '');
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
