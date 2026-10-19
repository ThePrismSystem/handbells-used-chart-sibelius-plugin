// The piece's instruments, as the dialog lists them and the plan reads them:
// a name and the run of staves each one occupies. ManuScript offers no
// instrument object to walk, so they are recovered from the staves.
//
// Like ScoreHeadChoices, this runs before any existing chart is removed, so
// the chart's own staves are left out by way of its marker. Never by
// instrument type: the chart is drawn on a generic treble-clef instrument that
// a user's own score is entitled to use.
ScoreInstruments(score) {
    lastStaff = score.StaffCount;
    found = FindChart(score);
    if (found.found) {
        lastStaff = found.firstStaff - 1;
    }

    staves = CreateSparseArray();
    n = 1;
    while (n <= lastStaff) {
        staff = score.NthStaff(n);
        // NumStavesInSameInstrument is documented as the stave count of the
        // default instrument the staff was created from, not its current
        // count. An instrument given an extra staff by hand may group wrong,
        // which is why the integration test traces every grouping it finds.
        staves.Push(CreateDictionary('num', n,
            'name', InstrumentLabelOf(staff.FullInstrumentName, staff.InstrumentName),
            'span', staff.NumStavesInSameInstrument));
        n = n + 1;
    }
    return GroupStaves(staves);
}

// Pure, so the grouping can be tested without a score. Each entry is one
// staff in score order; its span says how many staves, itself included,
// belong to its instrument.
GroupStaves(staves) {
    instruments = CreateSparseArray();
    if (staves.Length = 0) {
        return instruments;
    }
    final = staves[staves.Length - 1];
    lastNum = final.num;

    i = 0;
    while (i < staves.Length) {
        staff = staves[i];
        // A span that reads as 0 still covers the staff it was read from, and
        // one reaching past the last staff stops there rather than claiming
        // staves that do not exist.
        span = staff.span;
        if (span < 1) {
            span = 1;
        }
        last = (staff.num + span) - 1;
        if (last > lastNum) {
            last = lastNum;
        }
        instruments.Push(CreateDictionary('name', staff.name,
            'firstStaff', staff.num, 'lastStaff', last));
        i = (i + (last - staff.num)) + 1;
    }
    return UniqueInstrumentNames(instruments);
}

// The list box returns names, not instruments, so two instruments sharing a
// name would be one entry that could be neither picked nor left out on its
// own. The second and later ones are numbered.
UniqueInstrumentNames(instruments) {
    counts = CreateDictionary();
    for i = 0 to instruments.Length {
        instrument = instruments[i];
        name = '' & instrument.name;
        if (counts[name] = null) {
            counts[name] = 1;
        } else {
            counts[name] = counts[name] + 1;
            instrument.name = name & (' (' & counts[name] & ')');
        }
    }
    return instruments;
}

// FullInstrumentName is empty for a staff the user never named, where
// InstrumentName gives the bracketed default, such as [Piano], which is what
// the Instruments dialog shows for it too.
InstrumentLabelOf(fullName, instrumentName) {
    if (('' & fullName) != '') {
        return '' & fullName;
    }
    return '' & instrumentName;
}

InstrumentNames(instruments) {
    names = CreateSparseArray();
    for i = 0 to instruments.Length {
        instrument = instruments[i];
        names.Push(instrument.name);
    }
    return names;
}

// Score order, whatever order the names arrive in: the chart lists the
// instruments the way the score does.
InstrumentsNamed(instruments, names) {
    chosen = CreateSparseArray();
    for i = 0 to instruments.Length {
        instrument = instruments[i];
        if (HeadListed(names, instrument.name) = 1) {
            chosen.Push(instrument);
        }
    }
    return chosen;
}

RecordsForInstruments(records, instruments) {
    kept = CreateSparseArray();
    for i = 0 to records.Length {
        record = records[i];
        inside = 0;
        for j = 0 to instruments.Length {
            instrument = instruments[j];
            if ((record.staff >= instrument.firstStaff) and (record.staff <= instrument.lastStaff)) {
                inside = 1;
            }
        }
        if (inside = 1) {
            kept.Push(record);
        }
    }
    return kept;
}
