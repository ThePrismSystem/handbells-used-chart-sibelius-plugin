// Not assertions: a report on what the running Sibelius actually offers and
// what the chart bars actually contain. Three things could not be settled from
// the language guide, and each costs a whole hand-run session to guess at.
Diagnose() {
    score = Sibelius.ActiveScore;
    if (score = null) {
        trace('DIAGNOSE: open a score first');
        return False;
    }

    // 1. Which notehead styles this Sibelius has, by name. The guide documents
    // 24 constants with no stemless diamond among them, but a score can carry
    // more, and NoteStyleName reads whatever is really there.
    trace('[notehead styles]');
    note = FirstNoteIn(score);
    if (note = null) {
        trace('no note found; open a score with at least one note');
    } else {
        was = note.NoteStyle;
        for i = 0 to 40 {
            note.NoteStyle = i;
            name = '' & note.NoteStyleName;
            if (name != '') {
                trace(i & ' = ' & name);
            }
        }
        note.NoteStyle = was;
    }

    // 2. What each of the first three bars actually holds. The time signature
    // is hidden by type and still prints, so the type is worth confirming.
    trace('[bar contents]');
    b = 1;
    while (b <= 3) {
        if (b <= score.NthStaff(1).BarCount) {
            TraceBarTypes(score.NthStaff(1).NthBar(b), 'staff1 bar' & b);
            TraceBarTypes(score.SystemStaff.NthBar(b), 'system bar' & b);
        }
        b = b + 1;
    }
    trace('[stemless diamond] lookup = ' & StemlessDiamondStyle(score));
    return True;
}

FirstNoteIn(score) {
    n = 1;
    while (n <= score.StaffCount) {
        staff = score.NthStaff(n);
        b = 1;
        while (b <= staff.BarCount) {
            for each NoteRest nr in staff.NthBar(b) {
                for each note in nr {
                    return note;
                }
            }
            b = b + 1;
        }
        n = n + 1;
    }
    return null;
}

TraceBarTypes(bar, label) {
    line = '';
    for each item in bar {
        line = line & (' ' & item.Type);
    }
    trace(label & ':' & line);

    // System text is the thing a chart bar must never take with it when it is
    // deleted. Moving it needs its style and its offsets, so both are reported.
    for each item in bar {
        if (item.Type = 'SystemTextItem') {
            trace('    text style=' & item.StyleId
                & ' dx=' & item.Dx & ' dy=' & item.Dy
                & ' [' & item.Text & ']');
        }
    }
}
