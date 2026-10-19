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

    // One name per instrument, used for the chart label and for any warning
    // that has to say which instrument it is about.
    AssertEquals(InstrumentName('bells'), 'Handbells', 'handbell name');
    AssertEquals(InstrumentName('chimes'), 'Handchimes', 'handchime name');
    AssertEquals(InstrumentName('smbs'), 'SMBs', 'SMB name');

    empty = BuildPlan(CreateSparseArray(), options);
    AssertEquals(empty.sections.Length, 0, 'no sections for no notes');
}

TestChartPlan() {
    instruments = CreateSparseArray(
        CreateDictionary('name', 'Handbells I', 'firstStaff', 1, 'lastStaff', 2),
        CreateDictionary('name', 'Handbells II', 'firstStaff', 3, 'lastStaff', 4),
        CreateDictionary('name', 'Piano', 'firstStaff', 5, 'lastStaff', 6));
    records = CreateSparseArray(
        CreateDictionary('pitch', 72, 'diatonic', 35, 'head', 'Normal', 'staff', 1),
        CreateDictionary('pitch', 74, 'diatonic', 36, 'head', 'Diamond', 'staff', 2),
        CreateDictionary('pitch', 72, 'diatonic', 35, 'head', 'Normal', 'staff', 3),
        CreateDictionary('pitch', 76, 'diatonic', 37, 'head', 'Normal', 'staff', 3),
        CreateDictionary('pitch', 77, 'diatonic', 38, 'head', 'Cross', 'staff', 4));

    separate = BuildChartPlan(records, CreateDictionary('bellHead', 'Normal',
        'chimeHead', 'Diamond', 'smbHead', NoNoteHead(),
        'instruments', instruments, 'mode', 'separate'));
    AssertEquals(separate.sections.Length, 3, 'two sections for the first choir, one for the second');
    s0 = separate.sections[0];
    AssertEquals(s0.label, 'Handbells I' & LabelDash() & 'Handbells Used: 1', 'full score label names the instrument');
    AssertEquals(s0.plainLabel, 'Handbells Used: 1', 'plain label is the label as today');
    AssertEquals(JoinNames(s0.owners), 'Handbells I', 'a separate section has one owner');
    s1 = separate.sections[1];
    AssertEquals(s1.label, 'Handbells I' & LabelDash() & 'Handchimes Used: 1', 'chimes follow bells within an instrument');
    s2 = separate.sections[2];
    AssertEquals(s2.label, 'Handbells II' & LabelDash() & 'Handbells Used: 2', 'second instrument after the first');
    AssertEquals(JoinNames(separate.emptyNames), 'Piano', 'an instrument with nothing to chart is named');
    AssertEquals(separate.warnings.Length, 1, 'warnings are reported once for the run');
    w0 = separate.warnings[0];
    AssertEquals(w0.type, 'unknown-notehead', 'the unrecognised head is still reported');

    combined = BuildChartPlan(records, CreateDictionary('bellHead', 'Normal',
        'chimeHead', 'Diamond', 'smbHead', NoNoteHead(),
        'instruments', instruments, 'mode', 'combined'));
    AssertEquals(combined.sections.Length, 2, 'combined pools every instrument');
    c0 = combined.sections[0];
    AssertEquals(c0.label, 'Handbells Used: 2', 'combined labels are unchanged');
    AssertEquals(c0.plainLabel, c0.label, 'combined plain label is the label');
    AssertEquals(JoinNames(c0.owners), 'Handbells I, Handbells II, Piano', 'combined sections belong to every selected instrument');
    AssertEquals(combined.emptyNames.Length, 0, 'combined names no empty instruments');

    one = BuildChartPlan(records, CreateDictionary('bellHead', 'Normal',
        'chimeHead', 'Diamond', 'smbHead', NoNoteHead(),
        'instruments', CreateSparseArray(instruments[0]), 'mode', 'separate'));
    o0 = one.sections[0];
    AssertEquals(o0.label, 'Handbells Used: 1', 'one instrument is never prefixed');

    narrowed = BuildChartPlan(CreateSparseArray(records[0]), CreateDictionary('bellHead', 'Normal',
        'chimeHead', 'Diamond', 'smbHead', NoNoteHead(),
        'instruments', CreateSparseArray(instruments[0], instruments[1]), 'mode', 'separate'));
    AssertEquals(JoinNames(narrowed.emptyNames), 'Handbells II', 'a passage missing an instrument names it');
}
