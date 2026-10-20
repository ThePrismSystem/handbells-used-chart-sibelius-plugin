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
        CreateDictionary('part', 'A', 'names', CreateSparseArray('Handbells I')),
        CreateDictionary('part', 'B', 'names', CreateSparseArray('Handbells II')),
        CreateDictionary('part', 'P', 'names', CreateSparseArray('Piano'))));
    AssertEquals(entries.Length, 2, 'the piano part gets no entry');
    e0 = entries[0];
    AssertEquals(e0.part, 'A', 'entries keep part order');
    AssertEquals(JoinNames(e0.sections), '0, 1', 'part A carries the first choir');
    first = sections[0];
    AssertEquals(first.splitLabel, 1, 'a one-choir part reads the plain label');

    sections = PartTestSections();
    PlanPartEntries(sections, CreateSparseArray(
        CreateDictionary('part', 'A', 'names', CreateSparseArray('Handbells I')),
        CreateDictionary('part', 'AB', 'names', CreateSparseArray('Handbells I', 'Handbells II'))));
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
        CreateDictionary('part', 'A', 'names', CreateSparseArray('Handbells I'))));
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
}
