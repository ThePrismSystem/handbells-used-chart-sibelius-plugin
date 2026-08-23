AssertReset() {
    g_passed = 0;
    g_failed = 0;
    g_failures = '';
}

AssertEquals(actual, expected, label) {
    if (actual = expected) {
        g_passed = (0 + g_passed) + 1;
    } else {
        g_failed = (0 + g_failed) + 1;
        g_failures = ('' & g_failures) & ('\n  ' & label & ': expected [' & expected & '] got [' & actual & ']');
    }
}

AssertTrue(value, label) {
    AssertEquals(value, True, label);
}

AssertReport() {
    summary = (0 + g_passed) & ' passed, ' & (0 + g_failed) & ' failed';
    if ((0 + g_failed) > 0) {
        summary = summary & ('' & g_failures);
    }
    return summary;
}
