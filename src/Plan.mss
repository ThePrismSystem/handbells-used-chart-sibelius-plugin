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
