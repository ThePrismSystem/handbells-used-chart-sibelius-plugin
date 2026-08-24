// Groups raw note records into the distinct bells and chimes a score uses.
// Which notehead means which is the user's to say: options.bellHead and
// options.chimeHead hold NoteStyleName values picked from the open score.
CollectBells(records, options) {
    bells = CreateSparseArray();
    chimes = CreateSparseArray();
    seenBell = CreateDictionary();
    seenChime = CreateDictionary();
    outOfRange = CreateSparseArray();
    seenOutOfRange = CreateDictionary();
    unknownNames = CreateSparseArray();
    seenUnknown = CreateDictionary();
    unknown = 0;
    unreadable = 0;
    // H2: coerced once here rather than at every comparison in the loop. The
    // no-notehead entry is reduced to the empty choice, which matches nothing,
    // so a score charted as bells only needs no special case below.
    bellHead = '' & options.bellHead;
    chimeHead = '' & options.chimeHead;
    if (bellHead = NoNoteHead()) {
        bellHead = '';
    }
    if (chimeHead = NoNoteHead()) {
        chimeHead = '';
    }

    for i = 0 to records.Length {
        record = records[i];

        // H13 (`0 = null` evaluates TRUE) again, and this one bit: a record
        // whose diatonic is legitimately 0 was read as null and filed as
        // unreadable, so the out-of-range bell C0 never reached the chart's
        // warnings. `= null` cannot be used on a field that may hold a real
        // zero. IsNumeric separates them, because a null coerces to a string
        // that is not a number while 0 coerces to '0'.
        readable = 1;
        if (not(utils.IsNumeric('' & record.pitch, True))) {
            readable = 0;
        }
        if (not(utils.IsNumeric('' & record.diatonic, True))) {
            readable = 0;
        }

        if (readable = 1) {
            kind = '';
            // Guarded on the choice, not just on the head. A note whose
            // NoteStyleName failed to read arrives with an empty head, and
            // an empty choice would then match it and chart it as a bell.
            if (bellHead != '') {
                if (record.head = bellHead) { kind = 'bells'; }
            }
            if (chimeHead != '') {
                if (record.head = chimeHead) { kind = 'chimes'; }
            }

            if (kind = '') {
                unknown = unknown + 1;
                // Named, not just counted. The name printed here is the one to
                // pick in the dropdown, which is the whole of what a user needs
                // to know from this warning. Distinct, because it is a list of
                // heads to choose from and not a list of notes.
                if (record.head != '') {
                    if (seenUnknown[record.head] = null) {
                        seenUnknown[record.head] = 1;
                        unknownNames.Push(record.head);
                    }
                }
            } else {
                bell = BellNameOf(record.pitch, record.diatonic);
                region = RegionOf(record.diatonic);

                if (region = '') {
                    // 1, not True: H7 covers sparse arrays, and this is a
                    // dictionary, but a presence marker has no reason to be a
                    // Boolean either way. Dictionaries elsewhere in the plugin
                    // do carry Booleans and the suite asserts on them.
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
        } else {
            unreadable = unreadable + 1;
        }
    }

    return CreateDictionary(
        'bells', SortBells(bells),
        'chimes', SortBells(chimes),
        'unknown', unknown,
        'unknownNames', unknownNames,
        'unreadable', unreadable,
        'outOfRange', outOfRange
    );
}

// Ascending by pitch, then double-sharp through double-flat, matching the
// order published charts print enharmonic pairs in. Insertion sort: the lists
// are at most a few dozen entries and ManuScript has no sort of its own.
SortBells(list) {
    // ManuScript raises 'End value is not greater than the start value in a for
    // statement' when the end is BELOW the start, so `for i = 1 to 0` (an empty
    // collection) is a run-time error, not an empty loop. Proved in Sibelius by
    // a fixture with no bass bells at all.
    if (list.Length < 2) {
        return list;
    }
    for i = 1 to list.Length {
        current = list[i];
        j = i - 1;
        placed = 0;
        // Both operands are safe to evaluate at j = -1. The guide documents no
        // short-circuiting for `and`, only that 'both are true', so the
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
