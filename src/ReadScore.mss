// Turns the open score into the note records the plan is built from. Records
// are in bell space; this is the only file that reads raw Sibelius pitches.
ReadScoreNotes(score, skipFromStaff) {
    records = CreateSparseArray();
    selection = score.Selection;

    if (selection.IsPassage) {
        for each Bar bar in selection {
            // H6: a selected default barline comes back as a Bar rather than a
            // BarObject, and touching it crashes the plugin. IsObject is False
            // for these.
            if (IsObject(bar)) {
                ReadBarNotes(bar, records, skipFromStaff);
            }
        }
    } else {
        n = 1;
        while (n <= score.StaffCount) {
            staff = score.NthStaff(n);
            b = 1;
            while (b <= staff.BarCount) {
                ReadBarNotes(staff.NthBar(b), records, skipFromStaff);
                b = b + 1;
            }
            n = n + 1;
        }
    }

    return records;
}

ReadBarNotes(bar, records, skipFromStaff) {
    staff = bar.ParentStaff;
    if ((skipFromStaff > 0) and (staff.StaffNum >= skipFromStaff)) {
        return False;
    }

    for each NoteRest nr in bar {
        // H3: `for each Note n in nr` does not work. Notes inside a NoteRest
        // must be iterated untyped.
        for each n in nr {
            bell = ToBellSpace(n.Pitch, n.DiatonicPitch, staff);
            records.Push(CreateDictionary(
                'pitch', bell.pitch,
                'diatonic', bell.diatonic,
                'head', NoteHeadKind(n),
                'staffNum', staff.StaffNum
            ));
        }
    }
    return True;
}

NoteHeadKind(note) {
    if (note.NoteStyle = NormalNoteStyle) {
        return 'normal';
    }
    if (note.NoteStyle = DiamondNoteStyle) {
        return 'diamond';
    }
    return 'other';
}
