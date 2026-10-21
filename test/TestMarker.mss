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

    // The key and clef changes a build puts on an owner's staves where the
    // music starts are recorded beside the marker too, so a removal can take
    // them back off.
    restores = RestoreMarkerDecode(RestoreMarkerEncode(CreateSparseArray('3k', '4c')));
    AssertEquals(restores.Length, 2, 'the restore record round-trips');
    firstRestore = restores[0];
    AssertEquals(firstRestore.staff, 3, 'a restore names its staff');
    AssertEquals(firstRestore.kind, 'k', 'and what it put back');
    secondRestore = restores[1];
    AssertEquals(secondRestore.kind, 'c', 'a clef restore reads as one');
    AssertEquals(RestoreMarkerDecode('HBUCRESTORE'), null, 'a restore record restores something');
    AssertEquals(RestoreMarkerDecode('HBUCRESTORE|x'), null, 'a restore names a staff');
    AssertEquals(RestoreMarkerDecode('HBUCRESTORE|3q'), null, 'and puts back a key or a clef');
    AssertEquals(RestoreMarkerDecode('HBUC|1|1|4|12'), null, 'the chart marker is not a restore record');
    AssertEquals(RestoreMarkerDecode(NamesMarkerEncode(2)), null, 'nor is the names record');
    AssertEquals(MarkerDecode(RestoreMarkerEncode(CreateSparseArray('3k'))), null,
        'a restore record is not taken for the chart');
    AssertEquals(NamesMarkerDecode(RestoreMarkerEncode(CreateSparseArray('3k'))), -1,
        'or for the names record');
    AssertEquals(RestoreMarkerDecode(null), null, 'no text is no restore record');

    // Text that belongs to the first page stays there on a build.
    AssertTrue(StyleStaysOnFirstPage('text.system.page_aligned.title'), 'the title stays');
    AssertTrue(StyleStaysOnFirstPage('text.blankpage.plain'), 'blank-page text stays');
    AssertTrue(not(StyleStaysOnFirstPage('text.system.tempo')), 'a tempo mark moves');
}
