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
}
