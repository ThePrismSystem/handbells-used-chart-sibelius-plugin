ChartInstrument() {
    return '' & CHART_INSTRUMENT;
}

LabelTextStyle() {
    return '' & LABEL_TEXT_STYLE;
}

// H1: without this, every single-character literal in this plugin — the note
// letters, the accidental signs, the marker separator — is a 16-bit character
// value rather than a string, and concatenating one does arithmetic on its code
// point. Bell names would come out as numbers. Called from both plugins'
// Initialize, before anything else runs.
EnableStringSafety() {
    if (Sibelius.ProgramVersion > 20200600) {
        SetInterpreterOption(TreatSingleCharacterAsString);
    }
}
