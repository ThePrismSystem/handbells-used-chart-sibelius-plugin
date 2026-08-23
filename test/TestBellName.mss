TestBellName() {
    c5 = BellNameOf(72, 35);
    AssertEquals(c5.name, 'C5', 'C5 name');
    AssertEquals(c5.letter, 'C', 'C5 letter');
    AssertEquals(c5.alter, 0, 'C5 alter');
    AssertEquals(c5.octave, 5, 'C5 octave');

    gs5 = BellNameOf(80, 39);
    AssertEquals(gs5.name, 'G#5', 'G sharp 5 name');
    AssertEquals(gs5.alter, 1, 'G sharp 5 alter');

    ab5 = BellNameOf(80, 40);
    AssertEquals(ab5.name, 'Ab5', 'A flat 5 name');
    AssertEquals(ab5.alter, -1, 'A flat 5 alter');

    // Cb5 is octave 5 even though it sounds as B4.
    cb5 = BellNameOf(71, 35);
    AssertEquals(cb5.name, 'Cb5', 'C flat 5 name');
    AssertEquals(cb5.octave, 5, 'C flat 5 octave');

    AssertEquals(RegionOf(14), 'bassRow2', 'C2 region');
    AssertEquals(RegionOf(20), 'bassRow2', 'B2 region');
    AssertEquals(RegionOf(21), 'bassRow1', 'C3 region');
    AssertEquals(RegionOf(28), 'bassStaff', 'C4 region');
    AssertEquals(RegionOf(35), 'bassStaff', 'C5 region');
    AssertEquals(RegionOf(36), 'trebleStaff', 'D5 region');
    AssertEquals(RegionOf(49), 'trebleStaff', 'C7 region');
    AssertEquals(RegionOf(50), 'trebleRow1', 'D7 region');
    AssertEquals(RegionOf(57), 'trebleRow2', 'D8 region');
    AssertEquals(RegionOf(63), 'trebleRow2', 'C9 region');
    AssertEquals(RegionOf(13), '', 'below C2 is out of range');
    AssertEquals(RegionOf(64), '', 'above C9 is out of range');
}
