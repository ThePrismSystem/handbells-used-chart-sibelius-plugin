// The stack anchors on D6, not D5: trebleRow1 attaches at offset 12, so D7
// (pitch 98) anchors to pitch 86, which is D6. Anchoring the fixture on D5
// would leave D7 and D8 forming their own column and assert a shape the code
// cannot produce. A6 is the second column because it must sort after the
// stack's anchor pitch of 86.
//
// Every subscripted value is bound to a local before anything is read from it.
// Sibelius will not parse a chained subscript, and rejects the whole plug-in
// with a bare parse error when it meets one. Applying .Length to a subscripted
// expression is avoided for the same reason. `name.Length` and
// `name[i].Property` both parse and are used throughout the guide.
//
// Shapes are traced before they are asserted. These columns are assembled by
// four methods working together, and a bare assertion failure says only that
// the answer was wrong, not which stage produced the wrong answer.
TestColumns() {
    d6 = MakeBell(86, 43, 'trebleStaff');
    d7 = MakeBell(98, 50, 'trebleRow1');
    d8 = MakeBell(110, 57, 'trebleRow2');
    a6 = MakeBell(93, 47, 'trebleStaff');
    c3 = MakeBell(48, 21, 'bassRow1');
    c4 = MakeBell(60, 28, 'bassStaff');

    TraceBell('d6', d6);
    TraceBell('d7', d7);
    TraceBell('a6', a6);

    built = BuildColumns(CreateSparseArray(d6, d7, d8, a6, c3, c4), 0);

    treble = built.treble;
    bass = built.bass;
    TraceColumns('treble', treble);
    TraceColumns('bass', bass);

    AssertEquals(treble.Length, 2, 'two treble columns');
    AssertEquals(bass.Length, 2, 'two bass columns');
    AssertEquals(ColumnLength(treble, 0), 3, 'D stacks three octaves');
    AssertEquals(ColumnPitch(treble, 0, 0), 86, 'lowest in stack first');
    AssertEquals(ColumnPitch(treble, 0, 2), 110, 'highest in stack last');
    AssertEquals(ColumnLength(treble, 1), 1, 'A6 is its own column');
    AssertEquals(ColumnPitch(bass, 0, 0), 48, 'low bell leftmost');
    AssertEquals(ColumnPitch(bass, 1, 0), 60, 'staff bell after it');
    AssertEquals(built.length, 2, 'length is the wider side');
}

// Silver melody bells are charted on one treble staff, so a section drawn
// that way must route every bell to the treble columns. C5 is the case that
// matters: it regions as bassStaff, which is right for a two-staff section
// and would drop it off a chart whose bass staff is never drawn.
TestColumnsSingleStaff() {
    c3 = MakeBell(48, 21, 'bassRow1');
    c5 = MakeBell(72, 35, 'bassStaff');
    d5 = MakeBell(74, 36, 'trebleStaff');
    d6 = MakeBell(86, 43, 'trebleStaff');
    d7 = MakeBell(98, 50, 'trebleRow1');

    built = BuildColumns(CreateSparseArray(c3, c5, d5, d6, d7), 1);
    treble = built.treble;
    bass = built.bass;
    TraceColumns('single treble', treble);
    TraceColumns('single bass', bass);

    AssertEquals(bass.Length, 0, 'a one-staff section writes no bass columns');
    AssertEquals(treble.Length, 4, 'every bell reaches the treble staff');
    AssertEquals(ColumnPitch(treble, 1, 0), 72, 'C5 is on the treble staff');
    AssertEquals(ColumnPitch(treble, 2, 0), 74, 'D5 after it');
    // The octave stacking still works: D7 attaches to D6 twelve semitones down.
    AssertEquals(ColumnLength(treble, 3), 2, 'D6 and D7 still share a column');
    AssertEquals(ColumnPitch(treble, 3, 1), 98, 'the octave above sits on top');
    // A bell below the staff keeps its place rather than vanishing with the
    // bass staff that is not drawn.
    AssertEquals(ColumnPitch(treble, 0, 0), 48, 'a low bell sorts leftmost, not lost');
    AssertEquals(built.length, 4, 'length is the treble side');
}

MakeBell(pitch, diatonic, region) {
    bell = BellNameOf(pitch, diatonic);
    bell._property:region = region;
    bell._property:count = 1;
    return bell;
}

// Reports what is actually there instead of aborting the whole run on a null.
// A run-time error stops every remaining test, so one bad column would hide
// however many real results came after it.
ColumnLength(columns, index) {
    if (columns = null) {
        return -1;
    }
    column = columns[index];
    if (column = null) {
        return -2;
    }
    return column.Length;
}

ColumnPitch(columns, index, noteIndex) {
    if (columns = null) {
        return -1;
    }
    column = columns[index];
    if (column = null) {
        return -2;
    }
    note = column[noteIndex];
    if (note = null) {
        return -3;
    }
    return note.pitch;
}

TraceBell(label, bell) {
    if (bell = null) {
        trace(label & ' = null');
        return False;
    }
    trace(label & ' pitch=' & bell.pitch & ' diatonic=' & bell.diatonic
        & ' alter=' & bell.alter & ' region=' & bell.region);
    return True;
}

TraceColumns(label, columns) {
    if (columns = null) {
        trace(label & ' = null');
        return False;
    }
    trace(label & '.Length = ' & columns.Length);
    for i = 0 to columns.Length {
        column = columns[i];
        if (column = null) {
            trace('  ' & label & '[' & i & '] = null');
        } else {
            trace('  ' & label & '[' & i & '].Length = ' & column.Length
                & ' first=' & ColumnPitch(columns, i, 0));
        }
    }
    return True;
}

// The other half of AnchorColumns: an attachment whose anchor is not in the
// score at all. G7 has no G6 on the treble staff, so it becomes its own column
// - but it must still sort by the anchor it WOULD have had (91), not by its own
// pitch (103), or a piece that uses a high bell without its staff-octave
// partner prints that bell out of reading order.
TestColumnsOrphan() {
    a6 = MakeBell(93, 47, 'trebleStaff');
    g7 = MakeBell(103, 53, 'trebleRow1');

    built = BuildColumns(CreateSparseArray(a6, g7), 0);
    treble = built.treble;
    TraceColumns('orphan treble', treble);

    AssertEquals(treble.Length, 2, 'orphan attachment makes its own column');
    AssertEquals(ColumnPitch(treble, 0, 0), 103, 'orphan sorts by its absent anchor');
    AssertEquals(ColumnPitch(treble, 1, 0), 93, 'staff bell sorts after it');
}
