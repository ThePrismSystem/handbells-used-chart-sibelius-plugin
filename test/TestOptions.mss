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
}
