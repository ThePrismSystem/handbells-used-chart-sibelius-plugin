BuildPlan(records, options) {
    collected = CollectBells(records);
    sections = CreateSparseArray();

    if (collected.bells.Length > 0) {
        sections.Push(MakeSection('bells', collected.bells,
            options.bellLabel, 'Handbells Used'));
    }
    if (collected.chimes.Length > 0) {
        sections.Push(MakeSection('chimes', collected.chimes,
            options.chimeLabel, 'Handchimes Used'));
    }

    warnings = CreateSparseArray();
    if (collected.unknown > 0) {
        warnings.Push(CreateDictionary('type', 'unknown-notehead',
            'count', collected.unknown, 'names', CreateSparseArray()));
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

MakeSection(kind, entries, label, defaultLabel) {
    built = BuildColumns(entries);
    text = label;
    if (text = '') {
        text = defaultLabel & ': ' & DistinctPitches(entries);
    }
    return CreateDictionary(
        'kind', kind,
        'label', text,
        'columns', built.length,
        'treble', built.treble,
        'bass', built.bass
    );
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
