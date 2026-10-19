TestInstruments() {
    staves = CreateSparseArray(
        CreateDictionary('num', 1, 'name', 'Handbells I', 'span', 2),
        CreateDictionary('num', 2, 'name', 'Handbells I', 'span', 2),
        CreateDictionary('num', 3, 'name', 'Handbells II', 'span', 2),
        CreateDictionary('num', 4, 'name', 'Handbells II', 'span', 2),
        CreateDictionary('num', 5, 'name', 'Piano', 'span', 2),
        CreateDictionary('num', 6, 'name', 'Piano', 'span', 2)
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

    zero = GroupStaves(CreateSparseArray(CreateDictionary('num', 1, 'name', 'Flute', 'span', 0)));
    flute = zero[0];
    AssertEquals(flute.lastStaff, 1, 'a span of 0 still covers its own staff');

    short = GroupStaves(CreateSparseArray(
        CreateDictionary('num', 1, 'name', 'Flute', 'span', 1),
        CreateDictionary('num', 2, 'name', 'Piano', 'span', 2)));
    AssertEquals(short.Length, 2, 'a span past the last staff does not invent an instrument');
    piano = short[1];
    AssertEquals(piano.lastStaff, 2, 'a span past the last staff is cut at it');

    twins = GroupStaves(CreateSparseArray(
        CreateDictionary('num', 1, 'name', 'Handbells', 'span', 1),
        CreateDictionary('num', 2, 'name', 'Handbells', 'span', 1),
        CreateDictionary('num', 3, 'name', 'Handbells', 'span', 1)));
    AssertEquals(JoinNames(InstrumentNames(twins)), 'Handbells, Handbells (2), Handbells (3)',
        'instruments sharing a name are told apart');

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
