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
}
