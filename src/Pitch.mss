// A bell's name is its sounding pitch, an octave above written. Sibelius has
// no transposing handbell instrument, so the plugin applies that octave
// itself. The core downstream of here works entirely in bell-name space and
// so matches the MuseScore extension's lib/ exactly.
//
// Two constants below are both 7 in diatonic terms and cancel, leaving
// bellDiatonic equal to Sibelius's DiatonicPitch. THAT IS A COINCIDENCE, NOT
// A SHORTCUT. Sibelius's diatonic origin sits 7 above MuseScore's (35 versus
// 28 for middle C) and the handbell transposition is 7 diatonic steps; they
// compound to zero. Collapsing this expression, or changing one constant
// without the other, shifts every bell name by an octave and the chart still
// looks entirely plausible.

StaffChromaticTransposition(staff) {
    if (staff = null) {
        return 0;
    }
    t = staff.InitialInstrumentType;
    // Summed because the reference does not say how the two combine, and an
    // octave-transposing instrument reports in the second field, not the
    // first. Both read 0 on every instrument this plugin has been run against.
    return t.ChromaticTransposition + t.ChromaticTranspositionInScore;
}

StaffDiatonicTransposition(staff) {
    if (staff = null) {
        return 0;
    }
    t = staff.InitialInstrumentType;
    return t.DiatonicTransposition + t.DiatonicTranspositionInScore;
}

ToBellSpace(pitch, diatonic, staff) {
    bellTransposition = 12;
    bellTranspositionDiatonic = 7;
    sibeliusDiatonicOrigin = 7;

    written = pitch - StaffChromaticTransposition(staff);
    writtenDiatonic = diatonic - StaffDiatonicTransposition(staff);

    return CreateDictionary(
        'pitch', written + bellTransposition,
        'diatonic', (writtenDiatonic + bellTranspositionDiatonic) - sibeliusDiatonicOrigin
    );
}

FromBellSpace(bellPitch, bellDiatonic, staff) {
    bellTransposition = 12;
    bellTranspositionDiatonic = 7;
    sibeliusDiatonicOrigin = 7;

    written = bellPitch - bellTransposition;
    writtenDiatonic = (bellDiatonic - bellTranspositionDiatonic) + sibeliusDiatonicOrigin;

    return CreateDictionary(
        'pitch', written + StaffChromaticTransposition(staff),
        'diatonic', writtenDiatonic + StaffDiatonicTransposition(staff)
    );
}
