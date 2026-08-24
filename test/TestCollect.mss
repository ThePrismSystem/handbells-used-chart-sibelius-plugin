TestCollect() {
    // Real NoteStyleName values, not the plugin's own labels: the heads now
    // come straight off the notes and are compared against what the user
    // picked in the dialog, so a fixture using invented names would not
    // exercise the comparison the plugin actually makes.
    // Deliberately out of order: the bells arrive high-first so that the
    // insertion sort actually has to shift, including the pass that walks j
    // down to -1. A fixture already in ascending order never enters that
    // branch and would pass no matter what the sort did.
    records = CreateSparseArray(
        CreateDictionary('pitch', 80, 'diatonic', 39, 'head', 'Normal'),
        CreateDictionary('pitch', 72, 'diatonic', 35, 'head', 'Normal'),
        CreateDictionary('pitch', 80, 'diatonic', 40, 'head', 'Normal'),
        CreateDictionary('pitch', 72, 'diatonic', 35, 'head', 'Normal'),
        CreateDictionary('pitch', 74, 'diatonic', 36, 'head', 'Diamond'),
        CreateDictionary('pitch', 74, 'diatonic', 36, 'head', 'Cross'),
        CreateDictionary('pitch', 12, 'diatonic', 0, 'head', 'Normal')
    );
    options = CreateDictionary('bellHead', 'Normal', 'chimeHead', 'Diamond',
        'smbHead', NoNoteHead());
    got = CollectBells(records, options);

    AssertEquals(got.bells.Length, 3, 'three distinct bells');
    AssertEquals(got.bells[0].name, 'C5', 'lowest bell first');
    AssertEquals(got.bells[0].count, 2, 'repeated bell counted twice');
    // Same pitch, sharp before flat.
    AssertEquals(got.bells[1].name, 'G#5', 'sharp spelling before flat');
    AssertEquals(got.bells[2].name, 'Ab5', 'flat spelling after sharp');
    AssertEquals(got.chimes.Length, 1, 'one chime');
    AssertEquals(got.chimes[0].name, 'D5', 'chime name');
    AssertEquals(got.unknown, 1, 'unrecognised notehead counted');
    AssertEquals(got.unknownNames.Length, 1, 'the unrecognised head is named');
    AssertEquals(got.unknownNames[0], 'Cross', 'the unrecognised head name');
    AssertEquals(got.outOfRange.Length, 1, 'out of range recorded');
    AssertEquals(got.outOfRange[0], 'C0', 'out of range name');

    // The bug this feature exists for: a score whose chimes carry some other
    // notehead charted nothing as chimes and counted them all as unrecognised.
    // Choosing that head is all it should take.
    custom = CreateSparseArray(
        CreateDictionary('pitch', 72, 'diatonic', 35, 'head', 'Normal'),
        CreateDictionary('pitch', 74, 'diatonic', 36, 'head', 'Cross')
    );
    chosen = CollectBells(custom, CreateDictionary('bellHead', 'Normal', 'chimeHead', 'Cross',
        'smbHead', NoNoteHead()));
    AssertEquals(chosen.chimes.Length, 1, 'a chosen chime head is charted as chimes');
    AssertEquals(chosen.chimes[0].name, 'D5', 'chosen chime head name');
    AssertEquals(chosen.unknown, 0, 'a chosen chime head is not unrecognised');

    // Bells are chosen too, so a score whose bells are not the plain head
    // charts as well. The head that is no longer chosen becomes unrecognised.
    swapped = CollectBells(custom, CreateDictionary('bellHead', 'Cross', 'chimeHead', 'Diamond',
        'smbHead', NoNoteHead()));
    AssertEquals(swapped.bells.Length, 1, 'a chosen bell head is charted as bells');
    AssertEquals(swapped.bells[0].name, 'D5', 'chosen bell head name');
    AssertEquals(swapped.unknown, 1, 'the unchosen head is now unrecognised');
    AssertEquals(swapped.unknownNames[0], 'Normal', 'the unchosen head is named');

    // Repeats are named once, however many notes carry them: the warning is a
    // list of heads to choose from, not a list of notes.
    repeated = CreateSparseArray(
        CreateDictionary('pitch', 72, 'diatonic', 35, 'head', 'Cross'),
        CreateDictionary('pitch', 74, 'diatonic', 36, 'head', 'Cross'),
        CreateDictionary('pitch', 76, 'diatonic', 37, 'head', 'Slashed')
    );
    twice = CollectBells(repeated, CreateDictionary('bellHead', 'Normal', 'chimeHead', 'Diamond',
        'smbHead', NoNoteHead()));
    AssertEquals(twice.unknown, 3, 'every unrecognised note is counted');
    AssertEquals(twice.unknownNames.Length, 2, 'each unrecognised head is named once');

    // An empty choice matches nothing rather than matching every note whose
    // style name failed to read.
    blank = CreateSparseArray(
        CreateDictionary('pitch', 72, 'diatonic', 35, 'head', '')
    );
    none = CollectBells(blank, CreateDictionary('bellHead', '', 'chimeHead', '', 'smbHead', ''));
    AssertEquals(none.bells.Length, 0, 'an empty bell choice matches nothing');
    AssertEquals(none.chimes.Length, 0, 'an empty chime choice matches nothing');
    AssertEquals(none.unknown, 1, 'an unmatched note is counted as unrecognised');
    // A head whose name would not read is still counted, but there is no name
    // to offer, so nothing goes in the list rather than a blank entry.
    AssertEquals(none.unknownNames.Length, 0, 'an unnamed head contributes no name');

    // The common case the dropdowns must not break: a score with no chimes in
    // it opens with the chime box on the no-notehead entry, which has to chart
    // the bells and claim none of them as chimes.
    bellsOnly = CollectBells(custom,
        CreateDictionary('bellHead', 'Normal', 'chimeHead', NoNoteHead(), 'smbHead', NoNoteHead()));
    AssertEquals(bellsOnly.bells.Length, 1, 'no notehead chosen for chimes still charts bells');
    AssertEquals(bellsOnly.chimes.Length, 0, 'no notehead chosen for chimes charts no chimes');
    AssertEquals(bellsOnly.smbs.Length, 0, 'no notehead chosen for SMBs charts no SMBs');

    // Silver melody bells are a third instrument read the same way as the two
    // before them: a head of their own, counted and sorted like the rest.
    three = CreateSparseArray(
        CreateDictionary('pitch', 72, 'diatonic', 35, 'head', 'Normal'),
        CreateDictionary('pitch', 74, 'diatonic', 36, 'head', 'Diamond'),
        CreateDictionary('pitch', 79, 'diatonic', 38, 'head', 'Cross'),
        CreateDictionary('pitch', 76, 'diatonic', 37, 'head', 'Cross')
    );
    all3 = CollectBells(three, CreateDictionary('bellHead', 'Normal',
        'chimeHead', 'Diamond', 'smbHead', 'Cross'));
    AssertEquals(all3.bells.Length, 1, 'bells alongside two other instruments');
    AssertEquals(all3.chimes.Length, 1, 'chimes alongside two other instruments');
    AssertEquals(all3.smbs.Length, 2, 'two distinct SMBs');
    AssertEquals(all3.smbs[0].name, 'E5', 'SMBs sort by pitch like the rest');
    AssertEquals(all3.smbs[1].name, 'G5', 'SMBs sort by pitch like the rest');
    AssertEquals(all3.unknown, 0, 'a third chosen head leaves nothing unrecognised');
}
