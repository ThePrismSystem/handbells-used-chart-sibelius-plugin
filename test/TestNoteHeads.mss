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

    // Which head a column is actually drawn with. Handbells never need a
    // hand-made one, because StemlessNoteStyle is in every score.
    made = CreateDictionary('chimes', 40, 'smbs', 41);
    AssertEquals(CustomStyle('bells', made), -1, 'handbells have no hand-made head');
    AssertEquals(CustomStyle('chimes', made), 40, 'handchimes take the hand-made diamond');
    AssertEquals(CustomStyle('smbs', made), 41, 'SMBs take the hand-made square');

    AssertEquals(FallbackStyle('bells'), StemlessNoteStyle,
        'handbells fall back to the stemless head');
    AssertEquals(FallbackStyle('chimes'), DiamondNoteStyle,
        'handchimes fall back to the built-in diamond');
    AssertEquals(FallbackStyle('smbs'), ShapedNote6NoteStyle,
        'SMBs fall back to shaped note 6, which is the square');

    // Which hand-made notehead a section wants, and '' for one that wants
    // none. This is what decides whether a section can warn about a missing
    // head at all, so handbells returning '' is the whole of their exemption.
    AssertEquals(CustomStyleName('chimes'), StemlessDiamondName(),
        'handchimes want the stemless diamond');
    AssertEquals(CustomStyleName('smbs'), SquareStemlessName(),
        'SMBs want the stemless square');
    AssertEquals(CustomStyleName('bells'), '', 'handbells want no hand-made head');

    // Both built-in fallbacks carry stems, so a column using one is written
    // as whole notes to lose them. A hand-made head is stemless already.
    none = CreateDictionary('chimes', -1, 'smbs', -1);
    AssertEquals(ColumnTick('bells', none), 256, 'handbell columns are never whole notes');
    AssertEquals(ColumnTick('chimes', none), 1024, 'a missing diamond means whole notes');
    AssertEquals(ColumnTick('smbs', none), 1024, 'a missing square means whole notes');
    AssertEquals(ColumnTick('chimes', made), 256, 'a hand-made diamond keeps quarter notes');
    AssertEquals(ColumnTick('smbs', made), 256, 'a hand-made square keeps quarter notes');
}
