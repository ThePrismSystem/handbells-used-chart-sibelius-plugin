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

    // Text that belongs to the first page stays there on a build.
    AssertTrue(StyleStaysOnFirstPage('text.system.page_aligned.title'), 'the title stays');
    AssertTrue(StyleStaysOnFirstPage('text.blankpage.plain'), 'blank-page text stays');
    AssertTrue(not(StyleStaysOnFirstPage('text.system.tempo')), 'a tempo mark moves');
}
