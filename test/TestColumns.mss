// The stack anchors on D6, not D5: trebleRow1 attaches at offset 12, so D7
// (pitch 98) anchors to pitch 86, which is D6. Anchoring the fixture on D5
// would leave D7 and D8 forming their own column and assert a shape the code
// cannot produce. A6 is the second column because it must sort after the
// stack's anchor pitch of 86.
TestColumns() {
    d6 = MakeBell(86, 43, 'trebleStaff');
    d7 = MakeBell(98, 50, 'trebleRow1');
    d8 = MakeBell(110, 57, 'trebleRow2');
    a6 = MakeBell(93, 47, 'trebleStaff');
    c3 = MakeBell(48, 21, 'bassRow1');
    c4 = MakeBell(60, 28, 'bassStaff');

    built = BuildColumns(CreateSparseArray(d6, d7, d8, a6, c3, c4));

    AssertEquals(built.treble.Length, 2, 'two treble columns');
    AssertEquals(built.treble[0].Length, 3, 'D stacks three octaves');
    AssertEquals(built.treble[0][0].pitch, 86, 'lowest in stack first');
    AssertEquals(built.treble[0][2].pitch, 110, 'highest in stack last');
    AssertEquals(built.treble[1].Length, 1, 'A6 is its own column');
    AssertEquals(built.bass.Length, 2, 'two bass columns');
    AssertEquals(built.bass[0][0].pitch, 48, 'low bell leftmost');
    AssertEquals(built.bass[1][0].pitch, 60, 'staff bell after it');
    AssertEquals(built.length, 2, 'length is the wider side');
}

MakeBell(pitch, diatonic, region) {
    bell = BellNameOf(pitch, diatonic);
    bell._property:region = region;
    bell._property:count = 1;
    return bell;
}
