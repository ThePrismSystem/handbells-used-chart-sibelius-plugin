BuildChart(score, plan, options) {
    if (plan.sections.Length = 0) {
        return CreateDictionary('ok', True, 'error', '');
    }

    sections = plan.sections;
    pieceStaves = score.StaffCount;
    metre = ReadInitialTimeSignature(score);

    // 1. Bars first. A Sibelius bar spans every staff, so staves created
    //    afterwards inherit the irregular lengths already set. And sizing must
    //    precede the notes: until a bar declares its own length it still holds
    //    the score's ordinary metre, and a chart with more columns than the
    //    metre allows would spill into the piece's own bars.
    barsBefore = score.NthStaff(1).BarCount;
    columnsArray = CreateSparseArray();
    for i = 0 to sections.Length {
        columnsArray.Push(sections[i].columns);
        score.InsertBars(1, i + 1, sections[i].columns * 256);
    }
    if (score.NthStaff(1).BarCount != (barsBefore + sections.Length)) {
        return BuildFailure('Sibelius did not insert the chart bars.');
    }

    // 2. Instruments.
    staffCountBefore = score.StaffCount;
    trebleStaves = CreateSparseArray();
    bassStaves = CreateSparseArray();
    for i = 0 to sections.Length {
        treble = score.CreateInstrumentAtBottomReturnStave(ChartInstrument());
        if (treble = null) {
            return BuildFailure('Sibelius could not create the chart instrument.');
        }
        // A non-null return is not proof the style ID was found: asking for an
        // instrument that does not exist still adds an unnamed staff.
        if (treble.InitialStyleId != ChartInstrument()) {
            return BuildFailure('The chart instrument style ID was not recognised.');
        }
        bass = treble.AddStaffBelow(False);
        if (bass = null) {
            return BuildFailure('Sibelius could not add the chart bass staff.');
        }
        bass.NthBar(1).AddClef(0, 'clef.bass');
        trebleStaves.Push(treble);
        bassStaves.Push(bass);
    }
    if (score.StaffCount != (staffCountBefore + (sections.Length * 2))) {
        return BuildFailure('Sibelius did not add the chart staves.');
    }

    // 3. Marker, at the first moment it has somewhere to go.
    MarkerWrite(trebleStaves[0].NthBar(1), sections.Length, score.StaffCount, columnsArray);

    // 4. Columns.
    for i = 0 to sections.Length {
        color = '';
        if (sections[i].kind = 'chimes') {
            color = options.chimeColor;
        }
        WriteColumns(trebleStaves[i], i + 1, sections[i].treble, sections[i].kind, color);
        WriteColumns(bassStaves[i], i + 1, sections[i].bass, sections[i].kind, color);
    }

    // 5. Hide the structural furniture across every staff in the chart bars.
    for b = 0 to sections.Length {
        HideBarFurniture(score, b + 1);
    }

    // 6. Labels, breaks and staff size.
    for i = 0 to sections.Length {
        label = trebleStaves[i].NthBar(i + 1).AddText(0, sections[i].label, LabelTextStyle());
        bar = score.NthStaff(1).NthBar(i + 1);
        bar.BreakType = EndOfSystem;
        trebleStaves[i].Small = True;
        bassStaves[i].Small = True;
    }
    score.NthStaff(1).NthBar(sections.Length).SectionEnd = True;

    // 7. Hide empty staves, bar-scoped: the piece's staves vanish from the
    //    chart's systems and the chart's staves vanish from the music. Each
    //    side is empty exactly where the other needs it gone.
    score.HideEmptyStaves(1, pieceStaves, 1, sections.Length);
    score.HideEmptyStaves(pieceStaves + 1, score.StaffCount,
        sections.Length + 1, score.NthStaff(1).BarCount);

    RestoreTimeSignature(score, metre, sections.Length);

    return CreateDictionary('ok', True, 'error', '');
}

BuildFailure(message) {
    return CreateDictionary('ok', False, 'error', message
        & ' Delete the chart staves and their bars in Sibelius, then run this again.');
}

// Two passes per column, not one. H5: a Note object held across an AddNote on
// the same NoteRest may no longer refer to the notehead it did, because the
// chord's notes reorder by pitch as they arrive. So every note in a column is
// written first, and only then are they dressed by iterating the finished
// chord. The MuseScore version splits these for the same reason.
WriteColumns(staff, barNumber, columns, kind, color) {
    bar = staff.NthBar(barNumber);
    for c = 0 to columns.Length {
        notes = columns[c];
        position = c * 256;
        chord = null;

        for n = 0 to notes.Length {
            raw = FromBellSpace(notes[n].pitch, notes[n].diatonic, staff);
            note = bar.AddNote(position, raw.pitch, 256, False, 1, raw.diatonic);
            if (IsObject(note)) {
                chord = note.ParentNoteRest;
            }
        }

        if (IsObject(chord)) {
            for each n in chord {
                DressNote(n, kind, color);
            }
        }
    }
}

DressNote(note, kind, color) {
    if (kind = 'chimes') {
        note.NoteStyle = DiamondNoteStyle;
        if (color != '') {
            note.ColorRed = HexByte(color, 1);
            note.ColorGreen = HexByte(color, 3);
            note.ColorBlue = HexByte(color, 5);
        }
    }
    // A chart is an inventory of the bells a piece needs, so no natural sign
    // belongs on one. Sibelius prints one whenever a plain letter follows an
    // altered spelling of the same letter earlier in the bar, and a ringer
    // reads that as a second, separate bell rather than the same one.
    if (note.Accidental = Natural) {
        note.AccidentalStyle = HiddenAcc;
    }
}

// Reads two hex digits from a '#rrggbb' string. Anything unparseable yields 0,
// which leaves that channel black rather than failing the run.
HexByte(text, offset) {
    high = HexDigit(Substring(text, offset, 1));
    low = HexDigit(Substring(text, offset + 1, 1));
    return (high * 16) + low;
}

HexDigit(char) {
    digits = '0123456789abcdef';
    lower = LowerCase('' & char);
    for i = 0 to 16 {
        if (Substring(digits, i, 1) = lower) {
            return i;
        }
    }
    return 0;
}

// Rests padding a chart bar are structural, not musical, so every one is
// hidden. The two staves of a chart end at different columns by design, so at
// least one is padded on nearly every chart. Time signatures go the same way:
// a published chart shows no metre. Both run across every staff, because a
// chart bar crosses the piece's staves as well as the chart's.
// H4: AddSpecialBarline adds an object to the bar, so it must not run inside a
// `for each` over that bar's contents. Setting Hidden on an object being
// iterated is fine — that changes a property, it does not add or remove.
HideBarFurniture(score, barNumber) {
    n = 1;
    while (n <= score.StaffCount) {
        bar = score.NthStaff(n).NthBar(barNumber);
        for each BarRest r in bar {
            r.Hidden = True;
        }
        for each NoteRest nr in bar {
            if (nr.NoteCount = 0) {
                nr.Hidden = True;
            }
        }
        for each TimeSignature ts in bar {
            ts.Hidden = True;
        }
        bar.AddSpecialBarline(SpecialBarlineInvisible);
        n = n + 1;
    }
}

// Read before anything moves: this is the last point at which the piece's own
// metre can be read from the piece's own first bar.
ReadInitialTimeSignature(score) {
    for each TimeSignature ts in score.NthStaff(1).NthBar(1) {
        return CreateDictionary('numerator', ts.Numerator, 'denominator', ts.Denominator);
    }
    return null;
}

// The other half: hidden where the insert put it, written back where it came
// from. A score that never declared a metre must not acquire one, so a null
// signature does nothing.
RestoreTimeSignature(score, metre, chartBars) {
    if (metre = null) {
        return False;
    }
    bar = score.NthStaff(1).NthBar(chartBars + 1);
    for each TimeSignature ts in bar {
        return False;
    }
    bar.AddTimeSignature(metre.numerator, metre.denominator, False, False);
    return True;
}
