TestPlan() {
    records = CreateSparseArray(
        CreateDictionary('pitch', 72, 'diatonic', 35, 'head', 'Normal'),
        CreateDictionary('pitch', 80, 'diatonic', 39, 'head', 'Normal'),
        CreateDictionary('pitch', 80, 'diatonic', 40, 'head', 'Normal'),
        CreateDictionary('pitch', 74, 'diatonic', 36, 'head', 'Diamond'),
        CreateDictionary('pitch', 74, 'diatonic', 36, 'head', 'Cross')
    );
    options = CreateDictionary('bellHead', 'Normal', 'chimeHead', 'Diamond',
        'smbHead', NoNoteHead());
    plan = BuildPlan(records, options);

    AssertEquals(plan.sections.Length, 2, 'bells and chimes sections');
    AssertEquals(plan.sections[0].kind, 'bells', 'bells first');
    // Two spellings of pitch 80 are one physical bell, so the count is 2.
    AssertEquals(plan.sections[0].label, 'Handbells Used: 2', 'bell label counts pitches');
    AssertEquals(plan.sections[1].label, 'Handchimes Used: 1', 'chime label');
    AssertEquals(plan.warnings.Length, 1, 'one warning');
    AssertEquals(plan.warnings[0].type, 'unknown-notehead', 'warning type');

    // Silver melody bells come third, after the two instruments that were
    // there before them, and label themselves the same generated way.
    withSmbs = BuildPlan(records, CreateDictionary('bellHead', 'Normal',
        'chimeHead', 'Diamond', 'smbHead', 'Cross'));
    AssertEquals(withSmbs.sections.Length, 3, 'three sections');
    AssertEquals(withSmbs.sections[2].kind, 'smbs', 'SMBs come last');
    AssertEquals(withSmbs.sections[2].label, 'SMBs Used: 1', 'SMB label');
    // Bound to a local first: Sibelius will not parse .Length applied to a
    // subscripted expression, and the suite keeps to that everywhere.
    smbSection = withSmbs.sections[2];
    AssertEquals(smbSection.bass.Length, 0, 'the SMB section writes no bass columns');
    AssertEquals(smbSection.treble.Length, 1, 'the SMB bell is on the treble staff');
    AssertEquals(withSmbs.warnings.Length, 0, 'nothing unrecognised once every head is chosen');

    AssertEquals(PlanHasKind(withSmbs.sections, 'smbs'), 1, 'a planned kind is found');
    AssertEquals(PlanHasKind(plan.sections, 'smbs'), 0, 'an unplanned kind is not found');
    AssertEquals(PlanHasKind(CreateSparseArray(), 'bells'), 0, 'no sections holds no kind');

    empty = BuildPlan(CreateSparseArray(), options);
    AssertEquals(empty.sections.Length, 0, 'no sections for no notes');
}
