TestReadScore() {
    score = Sibelius.ActiveScore;
    if (score = null) {
        AssertTrue(False, 'open a score before running the integration tests');
        return False;
    }

    records = ReadScoreNotes(score, 0);
    AssertTrue(records.Length > 0, 'read at least one note from the open score');

    // Every record is in bell space, so nothing may be below C2 as a bell
    // unless the score really contains such a pitch.
    ok = True;
    for i = 0 to records.Length {
        if ((records[i].pitch = null) or (records[i].diatonic = null)) {
            ok = False;
        }
    }
    AssertTrue(ok, 'every record carries a pitch and a diatonic pitch');
}
