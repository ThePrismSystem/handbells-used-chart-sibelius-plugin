// Fresh every time: PlanPartEntries writes splitLabel onto the sections it is
// given, so one case must not see the marks another case left.
PartTestSections() {
    return CreateSparseArray(
        CreateDictionary('label', 'Handbells I - Handbells Used: 3', 'plainLabel', 'Handbells Used: 3',
            'owners', CreateSparseArray('Handbells I')),
        CreateDictionary('label', 'Handbells I - Handchimes Used: 2', 'plainLabel', 'Handchimes Used: 2',
            'owners', CreateSparseArray('Handbells I')),
        CreateDictionary('label', 'Handbells II - Handbells Used: 4', 'plainLabel', 'Handbells Used: 4',
            'owners', CreateSparseArray('Handbells II')));
}

// The part values here are strings standing in for DynamicPart objects:
// planning only carries them through, it never asks them anything.
TestParts() {
    sections = PartTestSections();
    AssertEquals(JoinNames(PartSections(sections, CreateSparseArray('Handbells I'))), '0, 1',
        'a choir part gets its own charts');
    AssertEquals(JoinNames(PartSections(sections, CreateSparseArray('Handbells I', 'Handbells II'))), '0, 1, 2',
        'a part holding two choirs gets both');
    piano = PartSections(sections, CreateSparseArray('Piano'));
    AssertEquals(piano.Length, 0, 'an unselected instrument gets nothing');

    sections = PartTestSections();
    entries = PlanPartEntries(sections, CreateSparseArray(
        PartInfo('A', CreateSparseArray('Handbells I')),
        PartInfo('B', CreateSparseArray('Handbells II')),
        PartInfo('P', CreateSparseArray('Piano'))));
    AssertEquals(entries.Length, 2, 'the piano part gets no entry');
    e0 = entries[0];
    AssertEquals(e0.part, 'A', 'entries keep part order');
    AssertEquals(JoinNames(e0.sections), '0, 1', 'part A carries the first choir');
    AssertEquals(JoinNames(e0.names), 'Handbells I', 'and the instruments that name it');
    first = sections[0];
    AssertEquals(first.splitLabel, 1, 'a one-choir part reads the plain label');

    sections = PartTestSections();
    PlanPartEntries(sections, CreateSparseArray(
        PartInfo('A', CreateSparseArray('Handbells I')),
        PartInfo('AB', CreateSparseArray('Handbells I', 'Handbells II'))));
    first = sections[0];
    AssertEquals(first.splitLabel, 0, 'a chart also in a two-choir part is named in every part');
    last = sections[2];
    AssertEquals(last.splitLabel, 0, 'a chart only in a two-choir part is named');

    sections = PartTestSections();
    noParts = PlanPartEntries(sections, CreateSparseArray());
    AssertEquals(noParts.Length, 0, 'a score with no parts plans nothing');
    first = sections[0];
    AssertEquals(first.splitLabel, 0, 'with no parts the label is not split');

    combined = CreateSparseArray(CreateDictionary('label', 'Handbells Used: 5', 'plainLabel', 'Handbells Used: 5',
        'owners', CreateSparseArray('Handbells I', 'Handbells II')));
    PlanPartEntries(combined, CreateSparseArray(
        PartInfo('A', CreateSparseArray('Handbells I'))));
    only = combined[0];
    AssertEquals(only.splitLabel, 0, 'a combined label is never split');

    // Sibelius keeps one staff showing in every system, so a chart bar a part
    // does not carry joins one of the part's own charts rather than standing
    // as a system of one empty staff. Positions are the part's own chart
    // order, -1 for another choir's chart.
    joined = PartChartSystems(CreateSparseArray(-1, 0, 1));
    AssertEquals(JoinNames(joined.shows), '0, 0, 1', 'a chart before the part charts joins the first');
    AssertEquals(JoinNames(joined.ends), '0, 1, 1', 'and shares its system');
    joined = PartChartSystems(CreateSparseArray(0, 1, -1));
    AssertEquals(JoinNames(joined.shows), '0, 1, 1', 'a chart after the part charts joins the last');
    AssertEquals(JoinNames(joined.ends), '1, 0, 1', 'and ends that system');
    joined = PartChartSystems(CreateSparseArray(0, -1, -1, 1));
    AssertEquals(JoinNames(joined.shows), '0, 0, 0, 1', 'charts between joins the one before them');
    AssertEquals(JoinNames(joined.ends), '0, 0, 1, 1', 'and every own chart still ends a system');
    joined = PartChartSystems(CreateSparseArray(-1, -1, 0));
    AssertEquals(JoinNames(joined.shows), '0, 0, 0', 'several charts before join the first');
    AssertEquals(JoinNames(joined.ends), '0, 0, 1', 'in one system');
    joined = PartChartSystems(CreateSparseArray(0));
    AssertEquals(JoinNames(joined.ends), '1', 'a part carrying the only chart ends its system');

    // The music starts on a new page after two or more charts, and after one
    // only when the box asks for it.
    AssertEquals(PartEndsPage(2, False), 1, 'two charts always end the page');
    AssertEquals(PartEndsPage(3, True), 1, 'and so do three with the box ticked');
    AssertEquals(PartEndsPage(1, False), 0, 'one chart shares its page by default');
    AssertEquals(PartEndsPage(1, True), 1, 'one chart ends the page with the box ticked');

    // Each chart bar's position among the part's own charts, -1 for a bar the
    // part does not carry.
    AssertEquals(JoinNames(CarriedPositions(4, CreateSparseArray(1, 3))), '-1, 0, -1, 1',
        'a part numbers its own charts in order');
    AssertEquals(JoinNames(CarriedPositions(2, CreateSparseArray(0, 1))), '0, 1', 'a part carrying every chart');

    // Which of a part's staves a chart bar hides, 1 for hidden: everything but
    // the shown chart's two staves, and its lower one too for a one-staff chart.
    AssertEquals(JoinNames(ChartBarHiddenStaves(2, 6, 0, 0)), '1, 1, 0, 0, 1, 1',
        'the first chart shows its two staves');
    AssertEquals(JoinNames(ChartBarHiddenStaves(2, 6, 1, 0)), '1, 1, 1, 1, 0, 0',
        'the second chart shows the next two');
    AssertEquals(JoinNames(ChartBarHiddenStaves(2, 6, 0, 1)), '1, 1, 0, 1, 1, 1',
        'a one-staff chart hides its lower staff');
    AssertEquals(JoinNames(ChartBarHiddenStaves(0, 4, 1, 0)), '1, 1, 0, 0',
        'a part of chart staves alone hides only the other chart');

    // Title text is found again after a build by style and text, and by how
    // many like it came first.
    seen = CreateSparseArray();
    AssertEquals(TitleOccurrence(seen, 'subtitle', 'x'), 1, 'the first of its kind');
    AssertEquals(TitleOccurrence(seen, 'subtitle', 'y'), 1, 'other text is another kind');
    AssertEquals(TitleOccurrence(seen, 'subtitle', 'x'), 2, 'the same style and text again is the second');
    kept = CreateSparseArray(
        TitleRecord('subtitle', 'x', 1, 0, 378),
        TitleRecord('subtitle', 'x', 2, 0, 100),
        TitleRecord('title', 'Test Drive', 1, 0, 496));
    second = TitleRecordFor(kept, 'subtitle', 'x', 2);
    AssertEquals(second.dy, 100, 'the second of two alike is its own record');
    title = TitleRecordFor(kept, 'title', 'Test Drive', 1);
    AssertEquals(title.dy, 496, 'a title is found by its style and text');
    AssertEquals(TitleRecordFor(kept, 'composer', 'x', 1), null, 'text that was not there has no record');

    // A line that moved during a run is reset to the full score's position
    // when it followed the full score before the run, and is lost when the
    // part had placed it itself.
    fullScore = TitleRecord('title', 'Test Drive', 1, 0, 496);
    AssertEquals(TitleRestoreAction(title, fullScore, 0, 496), 'keep', 'a line still where it was is left alone');
    AssertEquals(TitleRestoreAction(title, fullScore, 0, 0), 'reset', 'a line that followed the score is reset');
    AssertEquals(TitleRestoreAction(title, fullScore, 32, 496), 'reset', 'and so is one moved sideways');
    own = TitleRecord('title', 'Test Drive', 1, 0, 100);
    AssertEquals(TitleRestoreAction(own, fullScore, 0, 0), 'lost', 'a line placed in the part cannot be put back');
    AssertEquals(TitleRestoreAction(own, fullScore, 0, 100), 'keep', 'unless it never moved');
    AssertEquals(TitleRestoreAction(null, fullScore, 0, 0), 'keep', 'a line the part did not have is left alone');
    AssertEquals(TitleRestoreAction(title, null, 0, 0), 'lost', 'a line the score did not have cannot follow it');
}

PartInfo(part, names) {
    return CreateDictionary('part', part, 'names', names);
}

TitleRecord(style, text, n, dx, dy) {
    return CreateDictionary('style', style, 'text', text, 'n', n, 'dx', dx, 'dy', dy);
}
