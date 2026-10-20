TestMarker() {
    text = MarkerEncode(2, 6, CreateSparseArray(12, 9));
    AssertEquals(text, 'HBUC|1|2|6|12|9', 'encoded marker');

    got = MarkerDecode(text);
    AssertEquals(got.sections, 2, 'decoded sections');
    AssertEquals(got.totalStaves, 6, 'decoded total staves');
    AssertEquals(got.columns.Length, 2, 'decoded column count');
    AssertEquals(got.columns[0], 12, 'first column count');
    AssertEquals(got.columns[1], 9, 'second column count');

    AssertEquals(MarkerDecode('not a marker'), null, 'rejects foreign text');
    AssertEquals(MarkerDecode('HBUC|2|1|2|3'), null, 'rejects a future version');
    AssertEquals(MarkerDecode('HBUC|1|2|6|12'), null, 'rejects a short column list');

    // The names rule a build changes is kept beside the marker, never in it,
    // so a chart drawn before the record existed is still found.
    AssertEquals(NamesMarkerDecode(NamesMarkerEncode(2)), 2, 'the names record round-trips');
    AssertEquals(NamesMarkerDecode(NamesMarkerEncode(0)), 0, 'full names round-trip');
    AssertEquals(NamesMarkerDecode('HBUC|1|1|4|12'), -1, 'the chart marker is not a names record');
    AssertEquals(NamesMarkerDecode('HBUCNAMES|x'), -1, 'a names record holds a number');
    AssertEquals(NamesMarkerDecode('HBUCNAMES|5'), -1, 'and only one of the three settings');
    AssertEquals(MarkerDecode(NamesMarkerEncode(2)), null, 'a names record is not taken for the chart');
    AssertEquals(NamesMarkerDecode('HBUCNAMES|-1'), -1, 'a negative setting is refused');
    AssertEquals(NamesMarkerDecode('HBUCNAMES|3'), -1, 'a setting past the last is refused');
    AssertEquals(NamesMarkerDecode(null), -1, 'no text is no record');

    // Each part whose first page a build lowers keeps its own record of the
    // margin it had, kept beside the marker the way the names rule is.
    margin = MarginMarkerDecode(MarginMarkerEncode('3.4#2', 12.7, 0));
    AssertTrue(margin != null, 'a margin record round-trips');
    AssertEquals(margin.key, '3.4#2', 'the record names its part');
    AssertEquals(Round(margin.gap * 100), 1270, 'the margin keeps two decimal places');
    AssertEquals(margin.unique, 0, 'and whether the first page had margins of its own');
    unique = MarginMarkerDecode(MarginMarkerEncode('1#1', 20, 1));
    AssertEquals(unique.unique, 1, 'a first page with its own margins is remembered');
    AssertEquals(MarginMarkerDecode('HBUCMARGIN|3.4#1|x|0'), null, 'a margin record holds a number');
    AssertEquals(MarginMarkerDecode('HBUCMARGIN|3.4#1|1270'), null, 'a short margin record is refused');
    AssertEquals(MarginMarkerDecode(NamesMarkerEncode(2)), null, 'a names record is not a margin record');
    AssertEquals(MarginMarkerDecode(null), null, 'no text is no margin record');
    AssertEquals(NamesMarkerDecode(MarginMarkerEncode('1#1', 20, 1)), -1, 'a margin record is not a names record');
    AssertEquals(MarkerDecode(MarginMarkerEncode('1#1', 20, 1)), null, 'nor is it taken for the chart');

    // Text that belongs to the first page stays there on a build.
    AssertTrue(StyleStaysOnFirstPage('text.system.page_aligned.title'), 'the title stays');
    AssertTrue(StyleStaysOnFirstPage('text.blankpage.plain'), 'blank-page text stays');
    AssertTrue(not(StyleStaysOnFirstPage('text.system.tempo')), 'a tempo mark moves');
}
