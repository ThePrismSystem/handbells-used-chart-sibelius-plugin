ChartInstrument() {
    return '' & CHART_INSTRUMENT;
}

// The instrument a staff changes to where a part should lose a chart bar. Its
// staff draws nothing at all, so a bar where every staff of a part is this
// takes no room in that part.
HiddenInstrument() {
    return '' & HIDDEN_INSTRUMENT;
}

LabelTextStyle() {
    return '' & LABEL_TEXT_STYLE;
}

// What separates an instrument's name from the label of a chart drawn for it
// alone, as in 'Handbells I - Handbells Used: 25'. A plain hyphen, because
// Sibelius reads a plug-in file as 8-bit text and an en dash in it came out
// garbled. Kept in the manifest with the other score-facing text.
LabelDash() {
    return '' & LABEL_DASH;
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
// The other notehead the user makes by hand. Sibelius ships no square head at
// all - the documented styles run cross, diamond, triangle and the shaped
// notes with nothing square among them - so unlike the diamond there is not
// even a stemmed one to copy stemlessness onto.
SquareStemlessName() {
    return '' & SQUARE_STEMLESS;
}

NoNoteHead() {
    return '' & NO_NOTEHEAD;
}
