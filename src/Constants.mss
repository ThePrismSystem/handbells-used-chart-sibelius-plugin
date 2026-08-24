ChartInstrument() {
    return '' & CHART_INSTRUMENT;
}

LabelTextStyle() {
    return '' & LABEL_TEXT_STYLE;
}

// H1: without this, every single-character literal in this plugin (the note
// letters, the accidental signs, the marker separator) is a 16-bit character
// value rather than a string, and concatenating one does arithmetic on its code
// point. Bell names would come out as numbers. Called from both plugins'
// Initialize, before anything else runs.
EnableStringSafety() {
    if (Sibelius.ProgramVersion > 20200600) {
        SetInterpreterOption(TreatSingleCharacterAsString);
    }
}

// The notehead the user makes by hand; see the README. Kept next to the other
// score-facing names so renaming it is a one-line change in the manifest.
StemlessDiamondName() {
    return '' & STEMLESS_DIAMOND;
}

// Both notehead dropdowns carry this ahead of the score's own heads, because
// a score is entitled to have no chimes in it at all, and the alternative -
// opening the chime dropdown on whichever head happened to be found first -
// would chart a bells-only score's bells as chimes as well.
NoNoteHead() {
    return '' & NO_NOTEHEAD;
}
