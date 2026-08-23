TestCollect() {
    // Deliberately out of order: the bells arrive high-first so that the
    // insertion sort actually has to shift, including the pass that walks j
    // down to -1. A fixture already in ascending order never enters that
    // branch and would pass no matter what the sort did.
    records = CreateSparseArray(
        CreateDictionary('pitch', 80, 'diatonic', 39, 'head', 'normal'),
        CreateDictionary('pitch', 72, 'diatonic', 35, 'head', 'normal'),
        CreateDictionary('pitch', 80, 'diatonic', 40, 'head', 'normal'),
        CreateDictionary('pitch', 72, 'diatonic', 35, 'head', 'normal'),
        CreateDictionary('pitch', 74, 'diatonic', 36, 'head', 'diamond'),
        CreateDictionary('pitch', 74, 'diatonic', 36, 'head', 'square'),
        CreateDictionary('pitch', 12, 'diatonic', 0, 'head', 'normal')
    );
    got = CollectBells(records);

    AssertEquals(got.bells.Length, 3, 'three distinct bells');
    AssertEquals(got.bells[0].name, 'C5', 'lowest bell first');
    AssertEquals(got.bells[0].count, 2, 'repeated bell counted twice');
    // Same pitch, sharp before flat.
    AssertEquals(got.bells[1].name, 'G#5', 'sharp spelling before flat');
    AssertEquals(got.bells[2].name, 'Ab5', 'flat spelling after sharp');
    AssertEquals(got.chimes.Length, 1, 'one chime');
    AssertEquals(got.chimes[0].name, 'D5', 'chime name');
    AssertEquals(got.unknown, 1, 'unrecognised notehead counted');
    AssertEquals(got.outOfRange.Length, 1, 'out of range recorded');
    AssertEquals(got.outOfRange[0], 'C0', 'out of range name');
}
