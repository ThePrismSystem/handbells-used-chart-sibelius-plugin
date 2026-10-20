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
        PartInfo('A', '1.2#1', CreateSparseArray('Handbells I')),
        PartInfo('B', '3.4#1', CreateSparseArray('Handbells II')),
        PartInfo('P', '5.6#1', CreateSparseArray('Piano'))));
    AssertEquals(entries.Length, 2, 'the piano part gets no entry');
    e0 = entries[0];
    AssertEquals(e0.part, 'A', 'entries keep part order');
    AssertEquals(JoinNames(e0.sections), '0, 1', 'part A carries the first choir');
    AssertEquals(e0.key, '1.2#1', 'an entry carries the key its part is found by again');
    AssertEquals(JoinNames(e0.names), 'Handbells I', 'and the instruments that name it');
    first = sections[0];
    AssertEquals(first.splitLabel, 1, 'a one-choir part reads the plain label');

    sections = PartTestSections();
    PlanPartEntries(sections, CreateSparseArray(
        PartInfo('A', '1.2#1', CreateSparseArray('Handbells I')),
        PartInfo('AB', '1.2.3.4#1', CreateSparseArray('Handbells I', 'Handbells II'))));
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
        PartInfo('A', '1.2#1', CreateSparseArray('Handbells I'))));
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

    // How far a chart reaches above its treble staff, in spaces: never less
    // than its label, and more for bells written high on ledger lines. F5,
    // diatonic 45, is the top line.
    low = CreateDictionary('treble', CreateSparseArray(
        CreateSparseArray(NoteAt(38)), CreateSparseArray(NoteAt(45))));
    AssertEquals(ChartReach(low), 4, 'a chart within the staff reaches as far as its label');
    high = CreateDictionary('treble', CreateSparseArray(
        CreateSparseArray(NoteAt(40), NoteAt(63)), CreateSparseArray(NoteAt(52))));
    AssertEquals(ChartReach(high), 10, 'a high bell reaches half a space a step, and one more');
    empty = CreateDictionary('treble', CreateSparseArray());
    AssertEquals(ChartReach(empty), 4, 'a one-staff chart with nothing on the treble still has a label');

    // A staff is four spaces, so a reach converts through the staff size.
    AssertEquals(RaisedGap(20, 4, 7), 27, 'four spaces of a 7 mm staff add 7 mm');
    AssertEquals(Round(RaisedGap(15.5, 10, 6) * 10), 305, 'and ten spaces of a 6 mm staff add 15 mm');

    // A part is found again by the staves it holds and, among parts holding
    // the same staves, by its place in the order.
    AssertEquals(JoinNames(OccurrenceKeys(CreateSparseArray('3.4', '6.7', '3.4', ''))),
        '3.4#1, 6.7#1, 3.4#2, #1', 'two parts of the same staves are told apart by order');

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
}

PartInfo(part, key, names) {
    return CreateDictionary('part', part, 'key', key, 'names', names);
}

NoteAt(diatonic) {
    return CreateDictionary('pitch', 60, 'diatonic', diatonic);
}

TitleRecord(style, text, n, dx, dy) {
    return CreateDictionary('style', style, 'text', text, 'n', n, 'dx', dx, 'dy', dy);
}
