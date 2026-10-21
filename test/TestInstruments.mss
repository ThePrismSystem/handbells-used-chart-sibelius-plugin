TestInstruments() {
    staves = CreateSparseArray(
        StaffEntry(1, 'Handbells I', 2, 'bells'),
        StaffEntry(2, 'Handbells I', 2, 'bells'),
        StaffEntry(3, 'Handbells II', 2, 'bells'),
        StaffEntry(4, 'Handbells II', 2, 'bells'),
        StaffEntry(5, 'Piano', 2, 'piano'),
        StaffEntry(6, 'Piano', 2, 'piano')
    );
    got = GroupStaves(staves);
    AssertEquals(got.Length, 3, 'three instruments from six staves');
    first = got[0];
    AssertEquals(first.name, 'Handbells I', 'first instrument name');
    AssertEquals(first.firstStaff, 1, 'first instrument starts at staff 1');
    AssertEquals(first.lastStaff, 2, 'first instrument ends at staff 2');
    third = got[2];
    AssertEquals(third.firstStaff, 5, 'piano starts at staff 5');
    AssertEquals(third.lastStaff, 6, 'piano ends at staff 6');

    zero = GroupStaves(CreateSparseArray(StaffEntry(1, 'Flute', 0, 'flute')));
    flute = zero[0];
    AssertEquals(flute.lastStaff, 1, 'a span of 0 still covers its own staff');

    short = GroupStaves(CreateSparseArray(
        StaffEntry(1, 'Flute', 1, 'flute'),
        StaffEntry(2, 'Piano', 2, 'piano')));
    AssertEquals(short.Length, 2, 'a span past the last staff does not invent an instrument');
    piano = short[1];
    AssertEquals(piano.lastStaff, 2, 'a span past the last staff is cut at it');

    // The span is the stave count of the instrument the staff was created
    // from, so an instrument with a staff deleted by hand still claims two.
    // The staff after it belongs to another instrument type and is not taken.
    cut = GroupStaves(CreateSparseArray(
        StaffEntry(1, 'Handbells', 2, 'bells'),
        StaffEntry(2, 'Piano', 2, 'piano'),
        StaffEntry(3, 'Piano', 2, 'piano')));
    AssertEquals(cut.Length, 2, 'a span reaching into another instrument type stops there');
    cutBells = cut[0];
    AssertEquals(cutBells.lastStaff, 1, 'the handbells keep only their own staff');
    cutPiano = cut[1];
    AssertEquals(cutPiano.firstStaff, 2, 'the piano starts on its own first staff');
    AssertEquals(cutPiano.lastStaff, 3, 'and keeps both of its staves');

    twins = GroupStaves(CreateSparseArray(
        StaffEntry(1, 'Handbells', 1, 'bells'),
        StaffEntry(2, 'Handbells', 1, 'bells'),
        StaffEntry(3, 'Handbells', 1, 'bells')));
    AssertEquals(JoinNames(InstrumentNames(twins)), 'Handbells, Handbells (2), Handbells (3)',
        'instruments sharing a name are told apart');
    taken = GroupStaves(CreateSparseArray(
        StaffEntry(1, 'Handbells', 1, 'bells'),
        StaffEntry(2, 'Handbells (2)', 1, 'bells'),
        StaffEntry(3, 'Handbells', 1, 'bells')));
    AssertEquals(JoinNames(InstrumentNames(taken)), 'Handbells, Handbells (2), Handbells (3)',
        'a number is never one another instrument already uses');

    AssertEquals(InstrumentLabelOf('Handbells I', '[Handbells]'), 'Handbells I', 'a named staff keeps its name');
    AssertEquals(InstrumentLabelOf('', '[Piano]'), '[Piano]', 'an unnamed staff uses the displayed name');

    records = CreateSparseArray(
        CreateDictionary('pitch', 72, 'diatonic', 35, 'head', 'Normal', 'staff', 1),
        CreateDictionary('pitch', 74, 'diatonic', 36, 'head', 'Normal', 'staff', 3),
        CreateDictionary('pitch', 76, 'diatonic', 37, 'head', 'Normal', 'staff', 5));
    kept = RecordsForInstruments(records, CreateSparseArray(got[1]));
    AssertEquals(kept.Length, 1, 'only the second instrument is read');
    only = kept[0];
    AssertEquals(only.staff, 3, 'the record kept is the one on staff 3');
    pair = RecordsForInstruments(records, CreateSparseArray(got[0], got[2]));
    AssertEquals(pair.Length, 2, 'two instruments keep both their records');
    none = RecordsForInstruments(records, CreateSparseArray());
    AssertEquals(none.Length, 0, 'no instruments keeps nothing');

    named = InstrumentsNamed(got, CreateSparseArray('Piano', 'Handbells I'));
    AssertEquals(named.Length, 2, 'two instruments named');
    firstNamed = named[0];
    AssertEquals(firstNamed.name, 'Handbells I', 'score order is kept, not the order asked for');
}

StaffEntry(num, name, span, style) {
    return CreateDictionary('num', num, 'name', name, 'span', span, 'style', style);
}
