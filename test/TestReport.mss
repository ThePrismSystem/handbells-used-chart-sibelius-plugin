TestReport() {
    AssertEquals(JoinNames(CreateSparseArray()), '', 'no names joins to nothing');
    AssertEquals(JoinNames(CreateSparseArray('C2')), 'C2', 'one name needs no separator');
    AssertEquals(JoinNames(CreateSparseArray('C2', 'B9')), 'C2, B9', 'two names are comma separated');

    AssertEquals(WarningLines(CreateSparseArray()), '', 'no warnings makes no lines');

    unknown = CreateSparseArray(
        CreateDictionary('type', 'unknown-notehead', 'count', 3, 'names', CreateSparseArray())
    );
    AssertEquals(WarningLines(unknown),
        '3 note(s) with an unrecognised notehead were skipped',
        'unknown notehead line');

    // Naming the heads that were skipped is the difference between a warning
    // a user can act on and one that just says something went wrong: the name
    // it prints is the one to pick in the dropdown.
    named = CreateSparseArray(
        CreateDictionary('type', 'unknown-notehead', 'count', 64,
            'names', CreateSparseArray('Diamond', 'Cross'))
    );
    AssertEquals(WarningLines(named),
        '64 note(s) with an unrecognised notehead were skipped: Diamond, Cross',
        'unknown notehead line names the heads it skipped');

    unreadable = CreateSparseArray(
        CreateDictionary('type', 'unreadable-pitch', 'count', 1, 'names', CreateSparseArray())
    );
    AssertEquals(WarningLines(unreadable),
        '1 note(s) with an unreadable pitch were skipped',
        'unreadable pitch line');

    outOfRange = CreateSparseArray(
        CreateDictionary('type', 'out-of-range', 'count', 2,
            'names', CreateSparseArray('C0', 'B9'))
    );
    AssertEquals(WarningLines(outOfRange),
        'Bells outside C2-C9 were skipped: C0, B9',
        'out of range line names the bells');

    // Two warnings join with a newline, and a type the code does not know is
    // dropped rather than taking the run down inside the reporting path.
    both = CreateSparseArray(
        CreateDictionary('type', 'unknown-notehead', 'count', 3, 'names', CreateSparseArray()),
        CreateDictionary('type', 'something-else', 'count', 9, 'names', CreateSparseArray()),
        CreateDictionary('type', 'out-of-range', 'count', 1, 'names', CreateSparseArray('C0'))
    );
    AssertEquals(WarningLines(both),
        '3 note(s) with an unrecognised notehead were skipped\nBells outside C2-C9 were skipped: C0',
        'two known warnings join with a newline and an unknown type is dropped');

    // Raised while drawing rather than while planning: only the chart knows
    // whether the score carries the notehead the SMB columns want.
    missing = CreateSparseArray(
        CreateDictionary('type', 'missing-notehead', 'count', 0,
            'names', CreateSparseArray('Square (stemless)'))
    );
    AssertEquals(WarningLines(missing),
        'SMBs were drawn with plain noteheads because this score has no Square (stemless) notehead',
        'missing notehead line names the notehead to make');
}
