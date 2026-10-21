BuildPlan(records, options) {
    collected = CollectBells(records, options);
    sections = CreateSparseArray();

    if (collected.bells.Length > 0) {
        sections.Push(MakeSection('bells', collected.bells));
    }
    if (collected.chimes.Length > 0) {
        sections.Push(MakeSection('chimes', collected.chimes));
    }
    if (collected.smbs.Length > 0) {
        sections.Push(MakeSection('smbs', collected.smbs));
    }
    if (collected.pf.Length > 0) {
        sections.Push(MakeSection('pf', collected.pf));
    }
    if (collected.whitechapel.Length > 0) {
        sections.Push(MakeSection('whitechapel', collected.whitechapel));
    }

    warnings = CreateSparseArray();
    if (collected.unknown > 0) {
        warnings.Push(CreateDictionary('type', 'unknown-notehead',
            'count', collected.unknown, 'names', collected.unknownNames));
    }
    if (collected.unreadable > 0) {
        warnings.Push(CreateDictionary('type', 'unreadable-pitch',
            'count', collected.unreadable, 'names', CreateSparseArray()));
    }
    if (collected.outOfRange.Length > 0) {
        warnings.Push(CreateDictionary('type', 'out-of-range',
            'count', collected.outOfRange.Length, 'names', collected.outOfRange));
    }

    return CreateDictionary('sections', sections, 'warnings', warnings);
}

// The plan for the instruments the dialog selected, charted together or one
// set per instrument. Every section also records its plain label and the
// instruments it belongs to, which is what decides the parts it goes into.
//
// Charting apart needs two instruments to mean anything: one instrument
// charted on its own is the combined chart with its name stuck on the front,
// so it is charted combined.
BuildChartPlan(records, options) {
    instruments = options.instruments;
    // Warnings are about notes, not instruments. Read once over everything
    // selected, an unrecognised head is reported once rather than once for
    // every instrument that happens to use it.
    combined = BuildPlan(RecordsForInstruments(records, instruments), options);
    emptyNames = CreateSparseArray();

    if ((options.mode != 'separate') or (instruments.Length < 2)) {
        owners = InstrumentNames(instruments);
        for i = 0 to combined.sections.Length {
            section = combined.sections[i];
            section._property:plainLabel = section.label;
            section._property:owners = owners;
        }
        return CreateDictionary('sections', combined.sections,
            'warnings', combined.warnings, 'emptyNames', emptyNames);
    }

    sections = CreateSparseArray();
    for i = 0 to instruments.Length {
        instrument = instruments[i];
        own = BuildPlan(RecordsForInstruments(records, CreateSparseArray(instrument)), options);
        // Named rather than silently dropped: a choir the user asked for that
        // charts nothing is usually a passage selection that missed it.
        if (own.sections.Length = 0) {
            emptyNames.Push(instrument.name);
        }
        for j = 0 to own.sections.Length {
            section = own.sections[j];
            section._property:plainLabel = section.label;
            section.label = (instrument.name & LabelDash()) & section.label;
            section._property:owners = CreateSparseArray(instrument.name);
            sections.Push(section);
        }
    }
    return CreateDictionary('sections', sections,
        'warnings', combined.warnings, 'emptyNames', emptyNames);
}

// The label is generated and nothing overrides it. A dialog field for it was
// one more thing to fill in for a string that is trivially retyped in the
// score once the chart is there.
MakeSection(kind, entries) {
    built = BuildColumns(entries, UsesOneStaff(kind));
    return CreateDictionary(
        'kind', kind,
        'label', (InstrumentName(kind) & ' Used: ') & DistinctPitches(entries),
        'columns', built.length,
        'treble', built.treble,
        'bass', built.bass
    );
}

// The plural name of an instrument, written once because it is wanted twice:
// on the chart label, and in any warning that has to say which instrument it
// is about.
InstrumentName(kind) {
    if (kind = 'chimes') {
        return 'Handchimes';
    }
    if (kind = 'smbs') {
        return 'SMBs';
    }
    if (kind = 'pf') {
        return 'P&F Handbells';
    }
    if (kind = 'whitechapel') {
        return 'Whitechapel Handbells';
    }
    return 'Handbells';
}

// The label counts physical bells, so two spellings of one pitch count once.
DistinctPitches(entries) {
    seen = CreateDictionary();
    total = 0;
    for i = 0 to entries.Length {
        // '' & keeps the key a string. The guide describes a dictionary as
        // indexed by string, and every other lookup in this plugin builds a
        // string key; a bare number here would be the only exception.
        key = '' & entries[i].pitch;
        if (seen[key] = null) {
            seen[key] = 1;
            total = total + 1;
        }
    }
    return total;
}
