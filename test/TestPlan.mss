TestPlan() {
    records = CreateSparseArray(
        CreateDictionary('pitch', 72, 'diatonic', 35, 'head', 'Normal'),
        CreateDictionary('pitch', 80, 'diatonic', 39, 'head', 'Normal'),
        CreateDictionary('pitch', 80, 'diatonic', 40, 'head', 'Normal'),
        CreateDictionary('pitch', 74, 'diatonic', 36, 'head', 'Diamond'),
        CreateDictionary('pitch', 74, 'diatonic', 36, 'head', 'Cross')
    );
    options = CreateDictionary('bellLabel', '', 'chimeLabel', '',
        'bellHead', 'Normal', 'chimeHead', 'Diamond');
    plan = BuildPlan(records, options);

    AssertEquals(plan.sections.Length, 2, 'bells and chimes sections');
    AssertEquals(plan.sections[0].kind, 'bells', 'bells first');
    // Two spellings of pitch 80 are one physical bell, so the count is 2.
    AssertEquals(plan.sections[0].label, 'Handbells Used: 2', 'bell label counts pitches');
    AssertEquals(plan.sections[1].label, 'Handchimes Used: 1', 'chime label');
    AssertEquals(plan.warnings.Length, 1, 'one warning');
    AssertEquals(plan.warnings[0].type, 'unknown-notehead', 'warning type');

    custom = CreateDictionary('bellLabel', 'Bells', 'chimeLabel', '',
        'bellHead', 'Normal', 'chimeHead', 'Diamond');
    AssertEquals(BuildPlan(records, custom).sections[0].label, 'Bells', 'custom label wins');

    empty = BuildPlan(CreateSparseArray(), options);
    AssertEquals(empty.sections.Length, 0, 'no sections for no notes');
}
