BuildColumns(entries) {
    trebleStaff = FilterRegion(entries, 'trebleStaff');
    trebleRow1 = FilterRegion(entries, 'trebleRow1');
    trebleRow2 = FilterRegion(entries, 'trebleRow2');
    bassStaff = FilterRegion(entries, 'bassStaff');
    bassRow1 = FilterRegion(entries, 'bassRow1');
    bassRow2 = FilterRegion(entries, 'bassRow2');

    treble = AnchorColumns(trebleStaff,
        CreateSparseArray(trebleRow1, trebleRow2),
        CreateSparseArray(12, 24));

    lowBlock = AnchorColumns(bassRow1,
        CreateSparseArray(bassRow2),
        CreateSparseArray(-12));

    bass = lowBlock;
    staffColumns = SingleColumns(bassStaff);
    for i = 0 to staffColumns.Length {
        bass.Push(staffColumns[i]);
    }

    longest = treble.Length;
    if (bass.Length > longest) {
        longest = bass.Length;
    }

    return CreateDictionary('treble', treble, 'bass', bass, 'length', longest);
}

FilterRegion(entries, region) {
    out = CreateSparseArray();
    for i = 0 to entries.Length {
        if (entries[i].region = region) {
            out.Push(entries[i]);
        }
    }
    return out;
}

SingleColumns(list) {
    out = CreateSparseArray();
    for i = 0 to list.Length {
        out.Push(CreateSparseArray(list[i]));
    }
    return out;
}

// Builds columns around `anchors`, attaching each entry in `attachments` to
// the anchor `offset` semitones away with the same spelling. Two bells with
// the same letter and alteration share a diatonic step modulo 7, so an anchor
// is found by (pitch - offset, diatonic - offsetDiatonic), which matches
// spelling as well as pitch. An entry with no anchor becomes its own column,
// sorted as though its anchor existed, so left-to-right reading order stays
// ascending.
AnchorColumns(anchors, attachmentLists, offsets) {
    columns = CreateSparseArray();
    index = CreateDictionary();

    for i = 0 to anchors.Length {
        key = anchors[i].pitch & ':' & anchors[i].diatonic;
        index[key] = columns.Length;
        columns.Push(CreateDictionary(
            'sortPitch', anchors[i].pitch,
            'sortAlter', -anchors[i].alter,
            'notes', CreateSparseArray(anchors[i])
        ));
    }

    for a = 0 to attachmentLists.Length {
        list = attachmentLists[a];
        offset = offsets[a];
        offsetDiatonic = RoundDown((offset / 12) * 7);

        for j = 0 to list.Length {
            entry = list[j];
            anchorPitch = entry.pitch - offset;
            anchorDiatonic = entry.diatonic - offsetDiatonic;
            key = anchorPitch & ':' & anchorDiatonic;

            if (index[key] = null) {
                index[key] = columns.Length;
                columns.Push(CreateDictionary(
                    'sortPitch', anchorPitch,
                    'sortAlter', -entry.alter,
                    'notes', CreateSparseArray(entry)
                ));
            } else {
                columns[index[key]].notes.Push(entry);
            }
        }
    }

    SortColumns(columns);

    out = CreateSparseArray();
    for i = 0 to columns.Length {
        SortNotesByPitch(columns[i].notes);
        out.Push(columns[i].notes);
    }
    return out;
}

SortColumns(columns) {
    for i = 1 to columns.Length {
        current = columns[i];
        j = i - 1;
        // Both operands are safe at j = -1. ManuScript documents no
        // short-circuiting for `and`, so the loop must never index at j = -1.
        placed = 0;
        while ((j >= 0) and (placed = 0)) {
            if (ColumnSortsAfter(columns[j], current)) {
                columns[j + 1] = columns[j];
                j = j - 1;
            } else {
                placed = 1;
            }
        }
        columns[j + 1] = current;
    }
}

ColumnSortsAfter(a, b) {
    if (a.sortPitch > b.sortPitch) {
        return True;
    }
    if ((a.sortPitch = b.sortPitch) and (a.sortAlter > b.sortAlter)) {
        return True;
    }
    return False;
}

SortNotesByPitch(notes) {
    for i = 1 to notes.Length {
        current = notes[i];
        j = i - 1;
        // Both operands are safe at j = -1. ManuScript documents no
        // short-circuiting for `and`, so the loop must never index at j = -1.
        placed = 0;
        while ((j >= 0) and (placed = 0)) {
            if (notes[j].pitch > current.pitch) {
                notes[j + 1] = notes[j];
                j = j - 1;
            } else {
                placed = 1;
            }
        }
        notes[j + 1] = current;
    }
}
