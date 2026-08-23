// Semitone offset of each natural letter from C, indexed by letter step.
NaturalOffset(letterStep) {
    offsets = CreateSparseArray(0, 2, 4, 5, 7, 9, 11);
    return offsets[letterStep];
}

LetterName(letterStep) {
    letters = CreateSparseArray('C', 'D', 'E', 'F', 'G', 'A', 'B');
    return letters[letterStep];
}

AccidentalText(alter) {
    if (alter = -2) { return 'bb'; }
    if (alter = -1) { return 'b'; }
    if (alter = 1)  { return '#'; }
    if (alter = 2)  { return 'x'; }
    return '';
}

// The octave comes from the diatonic index, never from the pitch. The
// diatonic index already carries the spelled letter and its octave, so Cb5
// reads as octave 5 although it sounds as B4. Deriving the octave from the
// pitch breaks every flat-C spelling.
BellNameOf(bellPitch, bellDiatonic) {
    letterStep = bellDiatonic % 7;
    octave = RoundDown(bellDiatonic / 7);
    // '' & forces a string: LetterName returns a one-character literal, which
    // without H1's interpreter option is a code point, and even with it the
    // coercion documents the intent.
    letter = '' & LetterName(letterStep);
    natural = ((octave + 1) * 12) + (0 + NaturalOffset(letterStep));
    alter = bellPitch - natural;

    return CreateDictionary(
        'pitch', bellPitch,
        'diatonic', bellDiatonic,
        'letter', letter,
        'alter', alter,
        'octave', octave,
        'name', letter & AccidentalText(alter) & octave
    );
}

// Diatonic index is octave * 7 + letterStep, so the six regions are
// contiguous integer ranges covering C2 (14) through C9 (63).
RegionOf(bellDiatonic) {
    if ((bellDiatonic >= 14) and (bellDiatonic <= 20)) { return 'bassRow2'; }
    if ((bellDiatonic >= 21) and (bellDiatonic <= 27)) { return 'bassRow1'; }
    if ((bellDiatonic >= 28) and (bellDiatonic <= 35)) { return 'bassStaff'; }
    if ((bellDiatonic >= 36) and (bellDiatonic <= 49)) { return 'trebleStaff'; }
    if ((bellDiatonic >= 50) and (bellDiatonic <= 56)) { return 'trebleRow1'; }
    if ((bellDiatonic >= 57) and (bellDiatonic <= 63)) { return 'trebleRow2'; }
    return '';
}
