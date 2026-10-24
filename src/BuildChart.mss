BuildChart(score, plan, options) {
    if (plan.sections.Length = 0) {
        return CreateDictionary('ok', True, 'error', '');
    }

    sections = plan.sections;
    pieceStaves = score.StaffCount;
    metre = ReadInitialTimeSignature(score);
    opening = score.NthStaff(1).CurrentKeySignature(1);
    openingSharps = opening.Sharps;
    openingMajor = opening.Major;

    // 1. Bars first. A Sibelius bar spans every staff, so staves created
    //    afterwards inherit the irregular lengths already set. And sizing must
    //    precede the notes: until a bar declares its own length it still holds
    //    the score's ordinary metre, and a chart with more columns than the
    //    metre allows would spill into the piece's own bars.
    // Whether a section's stemless head exists decides how long its columns
    // are, so every head is settled, and any the score lacks copied in, before
    // a single bar is sized. Nothing else in the run can tell the user that a
    // section is about to be drawn hollow: the plan is built without the score.
    chosen = ChartHeads(score, sections, options);
    heads = chosen.heads;
    warnings = chosen.warnings;

    barsBefore = score.NthStaff(1).BarCount;
    columnsArray = CreateSparseArray();
    for i = 0 to sections.Length {
        columnsArray.Push(sections[i].columns);
        kind = sections[i].kind;
        head = heads[kind];
        score.InsertBars(1, i + 1, sections[i].columns * head.tick);
    }
    if (score.NthStaff(1).BarCount != (barsBefore + sections.Length)) {
        return BuildFailure('Sibelius did not insert the chart bars.');
    }

    // Tempo marks and the like are anchored to the score's first bar, and the
    // chart is now that bar, so a direction such as 'Allegro' would sit over
    // the chart rather than over the music it describes. They move down to the
    // first music bar. The title block, and any text in a blank-page style, is
    // left where it is: it belongs on the first page, which is the chart's.
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
        kind = sections[i].kind;
        color = SectionColor(kind, options);
        head = heads[kind];
        WriteColumns(trebleStaves[i], i + 1, sections[i].treble, head, color);
        WriteColumns(bassStaves[i], i + 1, sections[i].bass, head, color);
    }

    // 4b. The parts' copies, on each owner's own staves in the same bars. Here
    //     rather than later so their padding rests are hidden with the rest.
    roles = CopyStaffRoles(sections);
    if (roles.Length > 0) {
        ChartBarsInC(score, openingSharps, openingMajor, sections.Length);
    }
    tokens = PrepareCopyStaves(score, roles, sections.Length);
    WriteCopies(score, sections, options, heads);
    starts = HideOutsideCopies(score, roles, sections, sections.Length);
    if (tokens.Length > 0) {
        record = trebleStaves[0].NthBar(1).AddText(0, RestoreMarkerEncode(tokens), LabelTextStyle());
        record.Hidden = True;
    }
    if (starts.Length > 0) {
        startsRecord = trebleStaves[0].NthBar(1).AddText(0, StartsMarkerEncode(starts), LabelTextStyle());
        startsRecord.Hidden = True;
    }

    // 5. Hide the structural furniture across every staff in the chart bars.
    for b = 0 to sections.Length {
        HideBarFurniture(score, b + 1);
    }

    // 6. Labels, breaks and staff size.
    for i = 0 to sections.Length {
        section = sections[i];
        // The chart staves are in no part, so their label is the full score's
        // alone. The parts read the label on their copy.
        trebleStaves[i].NthBar(i + 1).AddText(0, section.label, LabelTextStyle());
        bar = score.NthStaff(1).NthBar(i + 1);
        bar.BreakType = EndOfSystemOrPage;
        trebleStaves[i].Small = True;
        bassStaves[i].Small = True;
    }
    score.NthStaff(1).NthBar(sections.Length).SectionEnd = True;

    // The music's first system now starts a new section, and Sibelius names
    // the instruments there by the new-section rule, which can be none where
    // the score's first system had full names. While the chart is in place it
    // takes the first system's rule, and the score's own is kept beside the
    // marker for a removal to put back.
    rules = score.EngravingRules;
    if (rules.InstrumentNamesNewSections != rules.InstrumentNamesFirstSystem) {
        kept = trebleStaves[0].NthBar(1).AddText(0,
            NamesMarkerEncode(rules.InstrumentNamesNewSections), LabelTextStyle());
        kept.Hidden = True;
        rules.InstrumentNamesNewSections = rules.InstrumentNamesFirstSystem;
    }

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
        // A one-staff section's lower staff is empty in its own bar as well,
        // because BuildColumns routed every bell to the treble side. Hiding it
        // is what makes the section print as the single staff it is meant to
        // be. The staff is still created, so the marker's staves-per-section
        // arithmetic, and with it the removal path, is left alone.
        if (UsesOneStaff(sections[i].kind) = 1) {
            score.HideEmptyStaves(top + 1, top + 1, i + 1, i + 1);
        }
    }

    RestoreTimeSignature(score, metre, sections.Length);

    // 8. Staff spacing, over the chart and the music's first system. A chart's
    //    ledger lines reach far past its staves into the system above, and the
    //    music's first system loses whatever spacing it had been given when
    //    the chart takes its place as the first system.
    score.OptimizeStaffSpacing(1, score.StaffCount, 1, sections.Length + 1);

    return CreateDictionary('ok', True, 'error', '', 'warnings', warnings);
}

// The staves PlanParts gave a copy, each once, with the clef its copy is drawn
// in: an owner's first staff takes the treble side and its second the bass.
// Dictionary{staff, clef} per staff. Sections PlanParts never saw have no
// copies, and _property: reads null for them where a plain read would stop
// the plug-in.
CopyStaffRoles(sections) {
    roles = CreateSparseArray();
    seen = CreateDictionary();
    for i = 0 to sections.Length {
        section = sections[i];
        copies = section._property:copies;
        if (copies != null) {
            for j = 0 to copies.Length {
                staves = copies[j];
                for k = 0 to staves.Length {
                    num = staves[k];
                    key = 'staff' & num;
                    if (seen[key] = null) {
                        seen[key] = 1;
                        clef = 'clef.treble';
                        if (k = 1) {
                            clef = 'clef.bass';
                        }
                        roles.Push(CreateDictionary('staff', num, 'clef', clef));
                    }
                }
            }
        }
    }
    return roles;
}

// A copy prints with no key, so every accidental shows as it does on the
// chart. A key with sharps or flats becomes C major in the chart bars and
// comes back where the music starts as an ordinary key change, on every
// staff. A removal deletes the chart bars, C major with them, and leaves that
// change as the music's opening key, so nothing in the music is hidden and
// nothing has to be put back. Any other key already prints no accidentals.
// The key is the one read before the chart bars went in, as nothing added
// since can have changed it.
ChartBarsInC(score, sharps, major, chartBars) {
    if ((sharps = 0) or (sharps = -8)) {
        return False;
    }
    score.NthStaff(1).NthBar(1).AddKeySignature(0, 0, True, False, False, False);
    score.NthStaff(1).NthBar(chartBars + 1).AddKeySignature(0, sharps, major, False, False, False);
    return True;
}

// Every copy staff made ready for its chart. Returns the restore record's
// tokens.
PrepareCopyStaves(score, roles, chartBars) {
    tokens = CreateSparseArray();
    for i = 0 to roles.Length {
        role = roles[i];
        made = PrepareCopyStaff(score, role.staff, role.clef, chartBars);
        for j = 0 to made.Length {
            tokens.Push(made[j]);
        }
    }
    return tokens;
}

// A copy prints in the clef it was drawn for. Where the staff's own clef
// differs, it gets a clef change in the first chart bar, and its own clef
// goes back where the music starts unless the music already starts with one.
// Read before anything changes, because the change moves what the next read
// would see. Returns a token per clef put back, for the restore record.
PrepareCopyStaff(score, staffNum, clef, chartBars) {
    tokens = CreateSparseArray();
    staff = score.NthStaff(staffNum);
    music = staff.NthBar(chartBars + 1);
    was = music.GetClefAt(0);
    wasConcert = '' & was.ConcertClefStyleId;
    wasTransposing = '' & was.TransposingClefStyleId;
    clefHere = 0;
    for each Clef c in music {
        if (c.Position = 0) {
            clefHere = 1;
        }
    }

    if (wasConcert != clef) {
        staff.NthBar(1).AddClef(0, clef);
        if (clefHere = 0) {
            music.AddClef(0, wasConcert, wasTransposing);
            tokens.Push(staffNum & 'c');
        }
    }
    return tokens;
}

// Each section's copies, drawn exactly as its chart is, in its own bar, with
// the label the parts read: the plain one when every part showing it holds a
// single charted instrument, which PlanPartEntries marks as splitLabel.
WriteCopies(score, sections, options, heads) {
    for i = 0 to sections.Length {
        section = sections[i];
        copies = section._property:copies;
        if (copies != null) {
            kind = section.kind;
            color = SectionColor(kind, options);
            head = heads[kind];
            text = section.label;
            if (section._property:splitLabel = 1) {
                text = section.plainLabel;
            }
            for j = 0 to copies.Length {
                staves = copies[j];
                top = score.NthStaff(staves[0]);
                WriteColumns(top, i + 1, section.treble, head, color);
                MarkPartsOnly(top.NthBar(i + 1));
                if (staves.Length > 1) {
                    lower = score.NthStaff(staves[1]);
                    WriteColumns(lower, i + 1, section.bass, head, color);
                    MarkPartsOnly(lower.NthBar(i + 1));
                }
                label = top.NthBar(i + 1).AddText(0, text, LabelTextStyle());
                label.ShowInParts();
            }
        }
    }
    return True;
}

// A copy staff is No instrument (hidden) in the chart bars StaffHiddenBars
// names, and its own instrument again where they end, so a part loses the
// bars of charts it does not carry instead of showing them as empty bars
// beside its own. The labels and warnings are hidden, there is no clef
// change. Sibelius names the staff after the instrument type it changes back
// to, Piano for a handbell staff made from one, so the change back carries the
// staff's own names, read before any change is made.
//
// Each change goes at the end of the bar before, as Sibelius puts the change
// back after a passage. One at the start of a bar that begins a system comes
// after that system's opening clef, which is then drawn, with the start of
// its staff lines, in the instrument before the change: a hidden one draws
// neither. So every change but one sits inside the chart bars, the music's
// first bar is untouched, and removing the chart bars removes them.
//
// The one is the change into bar 1, which has no bar before it. It makes no
// object at all: it changes the instrument the staff starts as, and deleting
// the chart bars would leave the staff hidden through the music. Returns
// those staves, each with the instrument it started as, for the starts record
// a removal reads to put them back.
HideOutsideCopies(score, roles, sections, chartBars) {
    starts = CreateSparseArray();
    for i = 0 to roles.Length {
        staffNum = roles[i].staff;
        staff = score.NthStaff(staffNum);
        own = staff.InitialStyleId;
        names = CreateDictionary(
            'full', staff.FullInstrumentNameWithFormatting,
            'short', staff.ShortInstrumentNameWithFormatting,
            'fullStaff', staff.FullStaffNameWithFormatting,
            'shortStaff', staff.ShortStaffNameWithFormatting);
        hidden = StaffHiddenBars(CopyBarsOfStaff(sections, staffNum), chartBars);
        if (hidden[0] = 1) {
            starts.Push(CreateDictionary('staff', staffNum, 'style', own));
        }
        hidden.Push(0);
        previous = 0;
        for b = 1 to chartBars + 2 {
            flag = hidden[b - 1];
            if (flag != previous) {
                target = own;
                if (flag = 1) {
                    target = HiddenInstrument();
                }
                if (b = 1) {
                    change = staff.NthBar(1).AddInstrumentChange(0, target, False, False, '', False);
                } else {
                    before = staff.NthBar(b - 1);
                    change = before.AddInstrumentChange(before.Length, target, False, False, '', False);
                }
                if (flag = 0) {
                    KeepStaffNames(change, names);
                }
            }
            previous = flag;
        }
    }
    return starts;
}

// A change back takes the names the staff had before any change. A change
// that made no object, which AddInstrumentChange reports with null, has
// nothing to take them.
KeepStaffNames(change, names) {
    if (not(IsObject(change))) {
        return False;
    }
    change.FullInstrumentNameWithFormatting = names.full;
    change.ShortInstrumentNameWithFormatting = names.short;
    change.FullStaffNameWithFormatting = names.fullStaff;
    change.ShortStaffNameWithFormatting = names.shortStaff;
    return True;
}

// A copy shows in the parts alone and plays on no pass: the full score has
// the chart already, and playback has no use for either.
MarkPartsOnly(bar) {
    for each NoteRest nr in bar {
        if (nr.NoteCount > 0) {
            nr.ShowInParts();
            p = 1;
            while (p <= 8) {
                nr.SetPlayedOnNthPass(p, False);
                p = p + 1;
            }
        }
    }
    return True;
}

// The colour belongs to the instrument, and only those given a dialog field
// for it have one. Handbells are the reference the others are read against,
// so they stay black.
SectionColor(kind, options) {
    if (kind = 'chimes') {
        return '' & options.chimeColor;
    }
    if (kind = 'smbs') {
        return '' & options.smbColor;
    }
    if (kind = 'pf') {
        return '' & options.pfColor;
    }
    if (kind = 'whitechapel') {
        return '' & options.whitechapelColor;
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
WriteColumns(staff, barNumber, columns, head, color) {
    bar = staff.NthBar(barNumber);
    for c = 0 to columns.Length {
        notes = columns[c];
        position = c * head.tick;
        chord = null;

        for n = 0 to notes.Length {
            raw = FromBellSpace(notes[n].pitch, notes[n].diatonic, staff);
            note = bar.AddNote(position, raw.pitch, head.tick, False, 1, raw.diatonic);
            if (IsObject(note)) {
                chord = note.ParentNoteRest;
            }
        }

        if (IsObject(chord)) {
            for each n in chord {
                DressNote(n, head);
            }
            ColorChord(chord, color);
        }
    }
}

// ManuScript exposes no writable stem property: Stemweight and StemFlipped are
// read-only, FlipStem only toggles direction, and stemlets are a different
// thing entirely. In Sibelius stemlessness IS a notehead style, so it is set
// here rather than on the NoteRest, and it is why every shape but round needs
// a stemless head of its own.
DressNote(note, head) {
    note.NoteStyle = head.style;
    // A chart is an inventory of the bells a piece needs, so no natural sign
    // belongs on one. Sibelius prints one whenever a plain letter follows an
    // altered spelling of the same letter earlier in the bar, and a ringer
    // reads that as a second, separate bell rather than the same one.
    if (note.Accidental = Natural) {
        note.AccidentalStyle = HiddenAcc;
    }
}

// A score can carry notehead styles beyond the 24 documented ones, and the
// stemless heads a chart is drawn with are among them, so they are found by
// name.
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

// Each section's head, keyed by kind, as ChartHead gives it, with a warning for
// every instrument drawn hollow. The stemless heads the score lacks are copied
// in from the notehead file together, so the file is opened once.
ChartHeads(score, sections, options) {
    kinds = CreateSparseArray();
    shapes = CreateDictionary();
    wanted = CreateSparseArray();
    for i = 0 to sections.Length {
        kind = sections[i].kind;
        if (HeadListed(kinds, kind) = 0) {
            kinds.Push(kind);
            music = HeadChosen(kind, options);
            shape = ChartShape(ShapeChosen(kind, options), NamedNoteStyle(score, music), music, kind);
            shapes[kind] = shape;
            name = ShapeHeadName(shape);
            if (name != '') {
                if (NamedNoteStyle(score, name) < 0) {
                    if (HeadListed(wanted, name) = 0) {
                        wanted.Push(name);
                    }
                }
            }
        }
    }
    if (wanted.Length > 0) {
        ImportHeads(score, wanted);
    }

    heads = CreateDictionary();
    warnings = CreateSparseArray();
    for i = 0 to kinds.Length {
        kind = kinds[i];
        shape = shapes[kind];
        name = ShapeHeadName(shape);
        head = ChartHead(shape, NamedNoteStyle(score, name));
        heads[kind] = head;
        if (head.tick = 1024) {
            warnings.Push(CreateDictionary('type', 'missing-notehead', 'count', 0,
                'names', CreateSparseArray(name), 'instrument', InstrumentName(kind)));
        }
    }
    return CreateDictionary('heads', heads, 'warnings', warnings);
}

// Colour is written on the NoteRest rather than on each Note, and only while
// it is selected. The reference is explicit that a BarObject's colour
// components can be written only when the object is selected, and a freshly
// added chart note is never selected, which is why setting the components on
// the notes did nothing whatever and every section came out black. Writing a
// property Sibelius will not accept is not an error: it just does not happen.
//
// Nothing per-note is lost. Every note in a chart column belongs to one
// instrument, so one colour per chord is all there ever is, and the reference
// says a NoteRest's colour reaches its notes anyway.
//
// The alpha channel is set with them. It is a separate component from the
// 24-bit colour, whose top bits the reference says are ignored, so a note that
// has never been coloured has no reason to carry an opaque one.
ColorChord(chord, color) {
    if (color = '') {
        return False;
    }
    chord.Select();
    chord.ColorRed = HexByte(color, 1);
    chord.ColorGreen = HexByte(color, 3);
    chord.ColorBlue = HexByte(color, 5);
    chord.ColorAlpha = 255;
    chord.Deselect();
    return True;
}

// Reads two hex digits from a '#rrggbb' string. Anything unparseable yields 0,
// which leaves that channel black rather than failing the run.
//
// Lower-casing is utils.LowerCase, not LowerCase: there is no global of that
// name, so the bare call resolved against this plug-in's own namespace, found
// nothing, and took the run down the first time anyone set a colour.
HexByte(text, offset) {
    high = HexDigit(Substring(text, offset, 1));
    low = HexDigit(Substring(text, offset + 1, 1));
    return (high * 16) + low;
}

HexDigit(char) {
    digits = '0123456789abcdef';
    lower = utils.LowerCase('' & char);
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
