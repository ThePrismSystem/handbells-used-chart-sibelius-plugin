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
}
