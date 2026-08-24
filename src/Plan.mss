BuildPlan(records, options) {
    collected = CollectBells(records, options);
    sections = CreateSparseArray();

    if (collected.bells.Length > 0) {
        sections.Push(MakeSection('bells', collected.bells, 'Handbells Used'));
    }
    if (collected.chimes.Length > 0) {
        sections.Push(MakeSection('chimes', collected.chimes, 'Handchimes Used'));
    }
    if (collected.smbs.Length > 0) {
        sections.Push(MakeSection('smbs', collected.smbs, 'SMBs Used'));
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
MakeSection(kind, entries, label) {
    built = BuildColumns(entries, UsesOneStaff(kind));
    return CreateDictionary(
        'kind', kind,
        'label', label & ': ' & DistinctPitches(entries),
        'columns', built.length,
        'treble', built.treble,
        'bass', built.bass
    );
}

// 1 or 0 rather than a Boolean, like HeadListed: the result is compared with =
// and the suite asserts on it.
PlanHasKind(sections, kind) {
    for i = 0 to sections.Length {
        if (sections[i].kind = kind) {
            return 1;
        }
    }
    return 0;
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
