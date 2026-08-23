TestPitch() {
    // Written middle C on a non-transposing staff is bell C5.
    b = ToBellSpace(60, 35, null);
    AssertEquals(b.pitch, 72, 'middle C bell pitch');
    AssertEquals(b.diatonic, 35, 'middle C bell diatonic');

    // Written D4 is bell D5.
    d = ToBellSpace(62, 36, null);
    AssertEquals(d.pitch, 74, 'D4 bell pitch');
    AssertEquals(d.diatonic, 36, 'D4 bell diatonic');

    // Round trip is the identity.
    r = FromBellSpace(b.pitch, b.diatonic, null);
    AssertEquals(r.pitch, 60, 'round trip pitch');
    AssertEquals(r.diatonic, 35, 'round trip diatonic');

    // Cb5 keeps its spelled octave: sounding 71, diatonic 35. Bell space
    // carries MuseScore's origin, where 28 is middle C, so 35 is C5.
    c = ToBellSpace(59, 35, null);
    AssertEquals(c.pitch, 71, 'Cb bell pitch');
    AssertEquals(c.diatonic, 35, 'Cb bell diatonic');
}
