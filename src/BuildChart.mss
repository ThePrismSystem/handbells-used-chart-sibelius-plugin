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
    // Whether the stemless diamond exists decides how long a chime column is,
    // so both hand-made noteheads are looked up before a single bar is sized.
    styles = CreateDictionary(
        'chimes', NamedNoteStyle(score, StemlessDiamondName()),
        'smbs', NamedNoteStyle(score, SquareStemlessName()));

    // Nothing else in the run can tell the user this: the plan is built
    // without the score, so only here is it known that the SMB columns are
    // about to be drawn with a head that is not square.
    warnings = CreateSparseArray();
    if (styles.smbs < 0) {
        if (PlanHasKind(sections, 'smbs') = 1) {
            warnings.Push(CreateDictionary('type', 'missing-notehead', 'count', 0,
                'names', CreateSparseArray(SquareStemlessName())));
        }
    }

    barsBefore = score.NthStaff(1).BarCount;
    columnsArray = CreateSparseArray();
    for i = 0 to sections.Length {
        columnsArray.Push(sections[i].columns);
        tick = ColumnTick(sections[i].kind, styles);
        score.InsertBars(1, i + 1, sections[i].columns * tick);
    }
    if (score.NthStaff(1).BarCount != (barsBefore + sections.Length)) {
        return BuildFailure('Sibelius did not insert the chart bars.');
    }

    // Tempo marks and the like are anchored to the score's first bar, and the
    // chart is now that bar, so a direction such as 'Allegro' would sit over
    // the chart rather than over the music it describes. They move down to the
    // first music bar. The title block is left exactly where it is: it belongs
    // at the top of the page, which is above the chart.
    RelocateSystemText(score, sections.Length, sections.Length + 1, True);

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
        SilenceKeySignature(treble);
        SilenceKeySignature(bass);
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
        color = SectionColor(sections[i].kind, options);
        tick = ColumnTick(sections[i].kind, styles);
        WriteColumns(trebleStaves[i], i + 1, sections[i].treble,
            sections[i].kind, color, styles, tick);
        WriteColumns(bassStaves[i], i + 1, sections[i].bass,
            sections[i].kind, color, styles, tick);
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

    NumberFromFirstMusicBar(score, sections.Length);

    // 7. Hide empty staves, bar-scoped: the piece's staves vanish from the
    //    chart's systems and the chart's staves vanish from the music. Each
    //    side is empty exactly where the other needs it gone.
    score.HideEmptyStaves(1, pieceStaves, 1, sections.Length);
    score.HideEmptyStaves(pieceStaves + 1, score.StaffCount,
        sections.Length + 1, score.NthStaff(1).BarCount);

    // And each section's staves must vanish from the OTHER sections' bars. The
    // two calls above only separate the piece from the chart; with two sections
    // they leave the chimes' empty staves sitting inside the bells' system and
    // the bells' inside the chimes', which is why a bells-only chart looked
    // right and a bells-and-chimes chart showed two blank staves per section.
    for i = 0 to sections.Length {
        top = (pieceStaves + (i * 2)) + 1;
        if (i > 0) {
            score.HideEmptyStaves(top, top + 1, 1, i);
        }
        if ((i + 2) <= sections.Length) {
            score.HideEmptyStaves(top, top + 1, i + 2, sections.Length);
        }
    }

    RestoreTimeSignature(score, metre, sections.Length);

    return CreateDictionary('ok', True, 'error', '', 'warnings', warnings);
}

// The colour belongs to the instrument, and only the two that were given a
// dialog field for it have one. Handbells are the reference the others are
// read against, so they stay black.
SectionColor(kind, options) {
    if (kind = 'chimes') {
        return '' & options.chimeColor;
    }
    if (kind = 'smbs') {
        return '' & options.smbColor;
    }
    return '';
}

BuildFailure(message) {
    return CreateDictionary('ok', False, 'warnings', CreateSparseArray(), 'error', message
        & ' Delete the chart staves and their bars in Sibelius, then run this again.');
}

// Two passes per column, not one. H5: a Note object held across an AddNote on
// the same NoteRest may no longer refer to the notehead it did, because the
// chord's notes reorder by pitch as they arrive. So every note in a column is
// written first, and only then are they dressed by iterating the finished
// chord. The MuseScore version splits these for the same reason.
WriteColumns(staff, barNumber, columns, kind, color, styles, tick) {
    bar = staff.NthBar(barNumber);
    for c = 0 to columns.Length {
        notes = columns[c];
        position = c * tick;
        chord = null;

        for n = 0 to notes.Length {
            raw = FromBellSpace(notes[n].pitch, notes[n].diatonic, staff);
            note = bar.AddNote(position, raw.pitch, tick, False, 1, raw.diatonic);
            if (IsObject(note)) {
                chord = note.ParentNoteRest;
            }
        }

        if (IsObject(chord)) {
            for each n in chord {
                DressNote(n, kind, color, styles);
            }
        }
    }
}

// ManuScript exposes no writable stem property: Stemweight and StemFlipped are
// read-only, FlipStem only toggles direction, and stemlets are a different
// thing entirely. In Sibelius stemlessness IS a notehead style, so it is set
// here rather than on the NoteRest, and it is why bells and chimes cannot both
// simply take their obvious style constant.
DressNote(note, kind, color, styles) {
    note.NoteStyle = StemlessNoteStyle;
    if (kind = 'chimes') {
        if (styles.chimes >= 0) {
            note.NoteStyle = styles.chimes;
        } else {
            note.NoteStyle = DiamondNoteStyle;
        }
    }
    // Silver melody bells keep the plain stemless head when the score has no
    // square one, because there is no built-in square to fall back to the way
    // chimes fall back to a stemmed diamond. That also means an SMB column
    // never needs the whole notes a chime column does: the head it falls back
    // to carries no stem already.
    if (kind = 'smbs') {
        if (styles.smbs >= 0) {
            note.NoteStyle = styles.smbs;
        }
    }
    // Out of the chimes branch: every instrument that was given a colour field
    // is coloured the same way, and one that was not is handed an empty colour.
    if (color != '') {
        note.ColorRed = HexByte(color, 1);
        note.ColorGreen = HexByte(color, 3);
        note.ColorBlue = HexByte(color, 5);
    }
    // A chart is an inventory of the bells a piece needs, so no natural sign
    // belongs on one. Sibelius prints one whenever a plain letter follows an
    // altered spelling of the same letter earlier in the bar, and a ringer
    // reads that as a second, separate bell rather than the same one.
    if (note.Accidental = Natural) {
        note.AccidentalStyle = HiddenAcc;
    }
}

// There is no stemless-diamond constant. The 24 documented styles pair a head
// shape with a stem setting, and only the plain head has a stemless variant, so
// chimes cannot get one the way bells do. A score can carry styles beyond those
// 24, and ManuScript cannot create one, so the plugin looks for a notehead the
// user made by hand. The README says how to make it.
//
// NoteStyleIndex belongs to Score, not to Sibelius. Calling it on the wrong
// object is not a parse error, it is 'Method NoteStyleIndex not found' at run
// time, in front of the user.
//
// Returns the style index, or -1 when the score has no such notehead.
NamedNoteStyle(score, name) {
    index = score.NoteStyleIndex(name);
    // An absent style comes back as an empty string on some builds and as a
    // negative index on others, so both are read as absent.
    if (not(utils.IsNumeric('' & index, True))) {
        return -1;
    }
    if (index < 0) {
        return -1;
    }
    return index;
}

// The fallback for a score with no stemless diamond: a semibreve carries no
// stem at any notehead style, so the chimes lose their stems by being whole
// notes instead. It costs the filled notehead, because a semibreve head is hollow,
// which is why the custom notehead is worth making. Bells never need this:
// StemlessNoteStyle is a documented constant present in every score.
ColumnTick(kind, styles) {
    if (kind = 'chimes') {
        if (styles.chimes < 0) {
            return 1024;
        }
    }
    return 256;
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
// iterated is fine, because that changes a property rather than adding or
// removing one.
// The system staff is where the time signature actually lives. Walking
// NthStaff(1) to StaffCount never reaches it, which is why hiding time
// signatures by type appeared to do nothing: there was no TimeSignature on any
// ordinary staff to hide. It runs first so a bar with nothing else in it is
// still cleared.
HideBarFurniture(score, barNumber) {
    HideBarObjects(score.SystemStaff.NthBar(barNumber));

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
        HideBarObjects(bar);
        bar.AddSpecialBarline(SpecialBarlineInvisible);
        n = n + 1;
    }
}

// Both signature types derive from BarObject, so both hide the same way. This
// runs on ordinary staves and on the system staff, which hold different things.
HideBarObjects(bar) {
    for each TimeSignature ts in bar {
        ts.Hidden = True;
    }
    for each KeySignature ks in bar {
        ks.Hidden = True;
    }
    return True;
}

// Hiding a KeySignature only works on one that exists as an object in the bar.
// A score's opening key is not one: it belongs to the staff, so a chart staff
// inherits it with nothing in any bar to hide. The chart staves therefore get
// an explicit key change of their own. Atonal, so no accidentals print at any
// system start; hidden, so the change itself does not print; and one-staff-only,
// so the piece's own staves keep the key they had.
SilenceKeySignature(staff) {
    staff.NthBar(1).AddKeySignature(0, -8, True, False, True, True);
    return True;
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

// The chart is bars, so without this the piece's own bar 1 becomes bar N+1 and
// every rehearsal reference in the score is wrong by the number of chart
// sections. The chart bars also pick up numbers of their own, which is where
// the stray number above a chart system comes from.
//
// Both are fixed with bar number changes rather than by counting: each chart
// bar gets one that does not increment, so the chart contributes nothing to
// the count, and the first music bar gets one that restarts at 1. Every change
// is hidden - a chart bar shows no number at all, and a piece's bar 1 is not
// numbered by convention either, while the bars after it number themselves 2,
// 3, 4 from the change.
NumberFromFirstMusicBar(score, chartBars) {
    b = 1;
    while (b <= chartBars) {
        HideBarNumber(score.NthStaff(1).NthBar(b), 1, True);
        b = b + 1;
    }
    HideBarNumber(score.NthStaff(1).NthBar(chartBars + 1), 1, False);
    return True;
}

HideBarNumber(bar, number, skipThisBar) {
    marker = bar.AddBarNumber(number, BarNumberFormatNormal, '', False, skipThisBar);
    if (IsObject(marker)) {
        marker.Hidden = True;
    }
    return True;
}
