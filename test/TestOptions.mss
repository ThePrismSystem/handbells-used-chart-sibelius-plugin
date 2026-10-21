TestOptions() {
    AssertEquals(Trim(''), '', 'trim of empty string');
    AssertEquals(Trim('   '), '', 'trim of only spaces');
    AssertEquals(Trim('abc'), 'abc', 'trim leaves an untrimmed string alone');
    AssertEquals(Trim('  abc'), 'abc', 'trim strips leading spaces');
    AssertEquals(Trim('abc  '), 'abc', 'trim strips trailing spaces');
    AssertEquals(Trim('  abc  '), 'abc', 'trim strips both ends');
    AssertEquals(Trim('a b'), 'a b', 'trim keeps interior spaces');
    AssertEquals(Trim(' a b '), 'a b', 'trim keeps interior spaces while stripping ends');
    // Trim coerces first, so a Data variable read still arrives as a string.
    AssertEquals(Trim(0), '0', 'trim coerces a number');

    AssertEquals(UsableColor(''), '', 'no colour given');
    AssertEquals(UsableColor('   '), '', 'only spaces is no colour');
    AssertEquals(UsableColor('c00000'), '#c00000', 'a bare hex value gains its hash');
    AssertEquals(UsableColor('#c00000'), '#c00000', 'a hashed hex value is left alone');
    AssertEquals(UsableColor(' #c00000 '), '#c00000', 'surrounding spaces are trimmed first');
    AssertEquals(UsableColor(' c00000 '), '#c00000', 'trimmed then hashed');
    AssertEquals(UsableColor('c000'), '', 'a short value is refused');
    AssertEquals(UsableColor('#c000000'), '', 'a long value is refused');
    AssertEquals(UsableColor('#'), '', 'a lone hash is refused');

    // The other half of a colour: UsableColor accepts the text, HexByte turns
    // it into the three channels a note is coloured with. Untested until a
    // bare LowerCase call in HexDigit took down the first run that set one.
    AssertEquals(HexDigit('0'), 0, 'zero');
    AssertEquals(HexDigit('9'), 9, 'nine');
    AssertEquals(HexDigit('a'), 10, 'lower case a');
    AssertEquals(HexDigit('f'), 15, 'lower case f');
    AssertEquals(HexDigit('A'), 10, 'upper case A');
    AssertEquals(HexDigit('F'), 15, 'upper case F');
    AssertEquals(HexDigit('z'), 0, 'a non-digit reads as zero');

    // Offsets are into '#rrggbb', so red starts at 1.
    AssertEquals(HexByte('#ff0000', 1), 255, 'red channel of lower case red');
    AssertEquals(HexByte('#ff0000', 3), 0, 'green channel of lower case red');
    AssertEquals(HexByte('#ff0000', 5), 0, 'blue channel of lower case red');
    AssertEquals(HexByte('#FF0000', 1), 255, 'upper case reads the same');
    AssertEquals(HexByte('#66FF00', 1), 102, 'mixed value red channel');
    AssertEquals(HexByte('#66FF00', 3), 255, 'mixed value green channel');
    AssertEquals(HexByte('#66FF00', 5), 0, 'mixed value blue channel');

    // Three instruments means three pairs to keep apart, not one.
    distinct = CreateDictionary('bellHead', 'Normal', 'chimeHead', 'Diamond',
        'smbHead', 'Square');
    AssertEquals(DuplicateHead(distinct), '', 'three different heads are fine');

    AssertEquals(DuplicateHead(CreateDictionary('bellHead', 'Normal',
        'chimeHead', 'Normal', 'smbHead', 'Square')), 'Normal',
        'handbells and handchimes sharing a head is caught');
    AssertEquals(DuplicateHead(CreateDictionary('bellHead', 'Normal',
        'chimeHead', 'Diamond', 'smbHead', 'Normal')), 'Normal',
        'handbells and SMBs sharing a head is caught');
    AssertEquals(DuplicateHead(CreateDictionary('bellHead', 'Normal',
        'chimeHead', 'Diamond', 'smbHead', 'Diamond')), 'Diamond',
        'handchimes and SMBs sharing a head is caught');

    // Any number of instruments may be absent from a piece, so the
    // no-notehead entry is the one value that may repeat.
    AssertEquals(DuplicateHead(CreateDictionary('bellHead', 'Normal',
        'chimeHead', NoNoteHead(), 'smbHead', NoNoteHead())), '',
        'two instruments left on no notehead is not a clash');
    AssertEquals(DuplicateHead(CreateDictionary('bellHead', NoNoteHead(),
        'chimeHead', NoNoteHead(), 'smbHead', NoNoteHead())), '',
        'a score with nothing chosen is not a clash');

    empty = PipeList('');
    AssertEquals(empty.Length, 0, 'an empty memory is no names');
    AssertEquals(JoinNames(PipeList('Piano|Flute')), 'Piano, Flute', 'memory splits on the pipe');
    AssertEquals(JoinPipe(CreateSparseArray('Piano', 'Flute')), 'Piano|Flute', 'memory joins on the pipe');
    AssertEquals(JoinPipe(CreateSparseArray()), '', 'no names joins to nothing');
    // An instrument name is the user's own text and may hold the separator.
    escaped = JoinPipe(CreateSparseArray('Bells A|B', 'Bells ~5'));
    AssertEquals(escaped, 'Bells A~pB|Bells ~~5', 'a pipe or tilde in a name is escaped');
    back = PipeList(escaped);
    AssertEquals(back.Length, 2, 'an escaped pipe does not split the name');
    AssertEquals(JoinNames(back), 'Bells A|B, Bells ~5', 'escaped names read back as they were');

    offered = CreateSparseArray('Handbells I', 'Handbells II', 'Piano');
    AssertEquals(JoinNames(PreselectedNames(offered, CreateSparseArray())),
        'Handbells I, Handbells II, Piano', 'a first run selects everything');
    AssertEquals(JoinNames(PreselectedNames(offered, CreateSparseArray('Piano', 'Flute'))),
        'Handbells I, Handbells II', 'a remembered exclusion applies, one absent from this score does not matter');
    AssertEquals(JoinNames(PreselectedNames(CreateSparseArray('Bells A'), CreateSparseArray('Handbells I'))),
        'Bells A', 'a renamed instrument is new, so it starts selected');

    AssertEquals(JoinNames(ExcludedAfterRun(CreateSparseArray(), offered,
        CreateSparseArray('Handbells I', 'Handbells II'))), 'Piano', 'leaving the piano out is remembered');
    AssertEquals(JoinNames(ExcludedAfterRun(CreateSparseArray('Piano', 'Flute'), offered, offered)),
        'Flute', 'selecting the piano again forgets it, and the flute is kept for a score that has one');
    AssertEquals(JoinNames(ExcludedAfterRun(CreateSparseArray('Flute'), offered, CreateSparseArray('Piano'))),
        'Flute, Handbells I, Handbells II', 'remembered names first, then this run in score order');
    AssertEquals(JoinNames(ExcludedAfterRun(CreateSparseArray('Flute'), offered, CreateSparseArray())),
        'Flute', 'a run with nothing selected changes nothing remembered');

    AssertEquals(ChartModeOf('' & CHART_MODE_SEPARATE), 'separate', 'the separate choice');
    AssertEquals(ChartModeOf('' & CHART_MODE_COMBINED), 'combined', 'the combined choice');
    AssertEquals(ChartModeOf(''), 'combined', 'no choice yet is combined, as v1.2.0');
    AssertEquals(ChartModeOf('something else'), 'combined', 'an unknown choice is combined');

    // A ticked parts box reached the run as unticked: the read only accepted
    // '1', and a ticked checkbox can hand back a Boolean, which reads 'true'.
    AssertTrue(Ticked(True), 'a checkbox holding True is ticked');
    AssertTrue(Ticked('true'), 'a checkbox reading true is ticked');
    AssertTrue(Ticked('1'), 'a checkbox reading 1 is ticked');
    AssertTrue(not(Ticked(False)), 'a checkbox holding False is not ticked');
    AssertTrue(not(Ticked('0')), 'the default 0 is not ticked');
    AssertTrue(not(Ticked('')), 'an empty checkbox value is not ticked');

    // The shape ReadOptions hands the list box, which is also the shape a
    // hand-run session saw the dialog hand back.
    dlg_instruments = CreateArray();
    dlg_instruments[0] = 'Handbells I';
    dlg_instruments[1] = 'Piano';
    AssertEquals(JoinNames(SelectedNames(dlg_instruments)), 'Handbells I, Piano',
        'the list selection reads back as names');
    dlg_instruments = CreateArray();
    nothing = SelectedNames(dlg_instruments);
    AssertEquals(nothing.Length, 0, 'an empty selection reads back as no names');
}
