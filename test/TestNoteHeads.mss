TestNoteHeads() {
    names = CreateSparseArray('Normal', 'Diamond', 'Cross');

    AssertEquals(HeadListed(names, 'Diamond'), 1, 'a used head is listed');
    AssertEquals(HeadListed(names, 'Slashed'), 0, 'an unused head is not listed');
    AssertEquals(HeadListed(names, ''), 0, 'the empty name is never listed');
    AssertEquals(HeadListed(CreateSparseArray(), 'Normal'), 0, 'nothing is listed in an empty score');

    // What the dialog opens on. The remembered value comes from the last run,
    // which may have been a different score, so it only wins while this score
    // still uses that notehead.
    AssertEquals(PreferredHead(names, 'Cross', 'Normal'), 'Cross',
        'a remembered head the score still uses wins');
    AssertEquals(PreferredHead(names, 'Slashed', 'Normal'), 'Normal',
        'an unusable remembered head falls back to the score default');
    AssertEquals(PreferredHead(names, '', 'Diamond'), 'Diamond',
        'nothing remembered falls back to the score default');
    // A bells-only score has no Diamond to fall back to. Guessing at one of
    // the heads it does use would chart its bells as chimes as well, which is
    // the whole reason the no-notehead entry exists.
    AssertEquals(PreferredHead(CreateSparseArray('Normal'), '', 'Diamond'), NoNoteHead(),
        'a missing fallback opens on no notehead');
    AssertEquals(PreferredHead(CreateSparseArray(), '', 'Diamond'), NoNoteHead(),
        'a score with no notes opens on no notehead');
    AssertEquals(PreferredHead(names, NoNoteHead(), 'Diamond'), 'Diamond',
        'the no-notehead entry is not itself a remembered head');

    items = HeadChoiceItems(names);
    AssertEquals(items.Length, 4, 'the list carries the no-notehead entry and every head');
    AssertEquals(items[0], NoNoteHead(), 'the no-notehead entry comes first');
    AssertEquals(items[1], 'Normal', 'the score heads follow in the order found');
    AssertEquals(HeadChoiceItems(CreateSparseArray()).Length, 1,
        'a score with no notes still offers the no-notehead entry');
}
