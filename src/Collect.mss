// Groups raw note records into the distinct bells and chimes a score uses.
CollectBells(records) {
    bells = CreateSparseArray();
    chimes = CreateSparseArray();
    seenBell = CreateDictionary();
    seenChime = CreateDictionary();
    outOfRange = CreateSparseArray();
    seenOutOfRange = CreateDictionary();
    unknown = 0;
    unreadable = 0;

    for i = 0 to records.Length {
        record = records[i];

        if ((record.pitch = null) or (record.diatonic = null)) {
            unreadable = unreadable + 1;
        } else {
            kind = '';
            if (record.head = 'normal')  { kind = 'bells'; }
            if (record.head = 'diamond') { kind = 'chimes'; }

            if (kind = '') {
                unknown = unknown + 1;
            } else {
                bell = BellNameOf(record.pitch, record.diatonic);
                region = RegionOf(record.diatonic);

                if (region = '') {
                    // 1, not True: H7, containers do not reliably hold Booleans.
                    if (seenOutOfRange[bell.name] = null) {
                        seenOutOfRange[bell.name] = 1;
                        outOfRange.Push(bell.name);
                    }
                } else {
                    key = record.pitch & ':' & record.diatonic;
                    if (kind = 'bells') {
                        if (seenBell[key] = null) {
                            bell._property:region = region;
                            bell._property:count = 0;
                            seenBell[key] = bell;
                            bells.Push(bell);
                        }
                        found = seenBell[key];
                        found.count = found.count + 1;
                    } else {
                        if (seenChime[key] = null) {
                            bell._property:region = region;
                            bell._property:count = 0;
                            seenChime[key] = bell;
                            chimes.Push(bell);
                        }
                        found = seenChime[key];
                        found.count = found.count + 1;
                    }
                }
            }
        }
    }

    return CreateDictionary(
        'bells', SortBells(bells),
        'chimes', SortBells(chimes),
        'unknown', unknown,
        'unreadable', unreadable,
        'outOfRange', outOfRange
    );
}

// Ascending by pitch, then double-sharp through double-flat, matching the
// order published charts print enharmonic pairs in. Insertion sort: the lists
// are at most a few dozen entries and ManuScript has no sort of its own.
SortBells(list) {
    for i = 1 to list.Length {
        current = list[i];
        j = i - 1;
        placed = 0;
        // Both operands are safe to evaluate at j = -1. The guide documents no
        // short-circuiting for `and` — it says only 'both are true' — so the
        // obvious `(j >= 0) and BellSortsAfter(list[j], current)` would index
        // list[-1] on the last pass and hand a null to BellSortsAfter, and the
        // guide is explicit that reading a property of null is a run-time error.
        while ((j >= 0) and (placed = 0)) {
            if (BellSortsAfter(list[j], current)) {
                list[j + 1] = list[j];
                j = j - 1;
            } else {
                placed = 1;
            }
        }
        list[j + 1] = current;
    }
    return list;
}

BellSortsAfter(a, b) {
    if (a.pitch > b.pitch) {
        return True;
    }
    if ((a.pitch = b.pitch) and (a.alter < b.alter)) {
        return True;
    }
    return False;
}
