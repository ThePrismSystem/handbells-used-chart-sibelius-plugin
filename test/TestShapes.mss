TestShapes() {
    // Sibelius's own heads are read by number, so their names make no
    // difference: a localised Sibelius spells them differently.
    AssertEquals(ShapeOfStyle(NormalNoteStyle, 'Normal'), ShapeRound(), 'the plain head is round');
    AssertEquals(ShapeOfStyle(StemlessNoteStyle, ''), ShapeRound(), 'the stemless head is round');
    AssertEquals(ShapeOfStyle(DiamondNoteStyle, 'Raute'), ShapeDiamond(),
        'a built-in head is read by number whatever it is called');
    AssertEquals(ShapeOfStyle(BlackAndWhiteDiamondNoteStyle, ''), ShapeDiamond(),
        'the black and white diamond is a diamond');
    AssertEquals(ShapeOfStyle(CrossNoteStyle, ''), '', 'the cross is none of the chart shapes');
    AssertEquals(ShapeOfStyle(InvertedTriangleNoteStyle, ''), ShapeInverted(),
        'the inverted triangle is an inverted triangle');
    AssertEquals(ShapeOfStyle(ArrowDownNoteStyle, ''), ShapeInverted(), 'the down arrow points down');
    AssertEquals(ShapeOfStyle(ArrowUpNoteStyle, ''), ShapeTriangle(), 'the up arrow points up');
    AssertEquals(ShapeOfStyle(ShapedNote1NoteStyle, ''), ShapeTriangle(), 'do is a triangle');
    AssertEquals(ShapeOfStyle(ShapedNote3NoteStyle, ''), ShapeDiamond(), 'mi is a diamond');
    AssertEquals(ShapeOfStyle(ShapedNote4StemDownNoteStyle, ''), ShapeTriangle(), 'fa is a triangle');
    AssertEquals(ShapeOfStyle(ShapedNote6NoteStyle, ''), ShapeSquare(), 'la is a square');
    AssertEquals(ShapeOfStyle(ShapedNote2NoteStyle, ''), ShapeHalfCircle(), 're is a half circle');
    AssertEquals(ShapeOfStyle(ShapedNote7NoteStyle, ''), ShapeCone(), 'ti is a cone');
    AssertEquals(ShapeOfStyle(HeadlessNoteStyle, 'Headless'), '', 'a headless note has no shape');

    // A head made by hand has only its name, and a copy is named after the
    // head it was made from.
    AssertEquals(ShapeOfStyle(31, 'Black & white diamond (2)'), ShapeDiamond(),
        'a copy is read by its name');
    AssertEquals(ShapeOfStyle(32, 'Inverted triangle (2)'), ShapeInverted(),
        'an inverted triangle is not read as a triangle');
    AssertEquals(ShapeOfStyle(33, 'Triangle (stemless)'), ShapeTriangle(), 'a triangle by name');
    AssertEquals(ShapeOfStyle(34, 'SQUARE'), ShapeSquare(), 'case makes no difference');
    AssertEquals(ShapeOfStyle(35, 'Cross (2)'), '', 'a cross is no shape by name either');
    AssertEquals(ShapeOfStyle(38, 'Half circle (stemless)'), ShapeHalfCircle(), 'a half circle by name');
    AssertEquals(ShapeOfStyle(39, 'Cone (stemless)'), ShapeCone(),
        'a cone is not read as round for its stemless name');
    AssertEquals(ShapeOfStyle(36, 'Normal (2)'), ShapeRound(), 'a copy of the plain head is round');
    AssertEquals(ShapeOfStyle(37, 'Chime'), '', 'a name with no shape in it has no shape');
    AssertEquals(ShapeOfStyle(-1, 'Diamond (stemless)'), ShapeDiamond(),
        'a head the score lacks is read by its name');

    // The shape a section is drawn in.
    AssertEquals(ChartShape(ShapeSquare(), DiamondNoteStyle, 'Diamond', 'chimes'), ShapeSquare(),
        'a chosen shape wins over the notehead');
    AssertEquals(ChartShape(ShapeMatch(), DiamondNoteStyle, 'Diamond', 'bells'), ShapeDiamond(),
        'matching takes the shape of the notehead');
    AssertEquals(ChartShape('', ShapedNote7NoteStyle, '', 'smbs'), ShapeCone(),
        'no choice at all matches the notehead');
    AssertEquals(ChartShape(ShapeMatch(), CrossNoteStyle, 'Cross', 'smbs'), ShapeSquare(),
        'SMBs written with crosses are charted as squares');
    AssertEquals(ChartShape(ShapeMatch(), 37, 'Chime', 'chimes'), ShapeDiamond(),
        'handchimes of no known shape are charted as diamonds');
    AssertEquals(ChartShape(ShapeMatch(), 37, 'Chime', 'smbs'), ShapeSquare(),
        'SMBs of no known shape are charted as squares');
    AssertEquals(ChartShape(ShapeMatch(), 37, 'Chime', 'bells'), ShapeRound(),
        'handbells of no known shape are charted round');
    AssertEquals(ChartShape(ShapeMatch(), 37, 'Chime', 'pf'), ShapeRound(),
        'P&F bells of no known shape are charted round');
    AssertEquals(ChartShape(ShapeMatch(), 37, 'Chime', 'whitechapel'), ShapeRound(),
        'Whitechapel bells of no known shape are charted round');

    // Round needs no head of its own: Stemless is in every score.
    AssertEquals(ShapeHeadName(ShapeRound()), '', 'round is drawn with the built-in head');
    AssertEquals(ShapeHeadName(ShapeDiamond()), 'Diamond (stemless)', 'the diamond head name');
    AssertEquals(ShapeHeadName(ShapeSquare()), 'Square (stemless)', 'the square head name');
    AssertEquals(ShapeHeadName(ShapeInverted()), 'Inverted triangle (stemless)',
        'the inverted triangle head name');
    AssertEquals(ShapeHeadName(ShapeHalfCircle()), 'Half circle (stemless)', 'the half circle head name');
    AssertEquals(ShapeHeadName(ShapeCone()), 'Cone (stemless)', 'the cone head name');

    // The head a column is drawn with, and how long it is. A stemless head
    // takes quarter notes; a built-in fallback carries stems, so its column
    // is written as whole notes to lose them.
    head = ChartHead(ShapeRound(), -1);
    AssertEquals(head.style, StemlessNoteStyle, 'round is the stemless head');
    AssertEquals(head.tick, 256, 'round is never whole notes');
    head = ChartHead(ShapeDiamond(), 40);
    AssertEquals(head.style, 40, 'a stemless head the score has is used');
    AssertEquals(head.tick, 256, 'a stemless head keeps quarter notes');
    head = ChartHead(ShapeDiamond(), -1);
    AssertEquals(head.style, DiamondNoteStyle, 'a missing diamond falls back to the built-in diamond');
    AssertEquals(head.tick, 1024, 'a fallback means whole notes');
    head = ChartHead(ShapeSquare(), -1);
    AssertEquals(head.style, ShapedNote6NoteStyle, 'a missing square falls back to la');
    head = ChartHead(ShapeTriangle(), -1);
    AssertEquals(head.style, ShapedNote1NoteStyle, 'a missing triangle falls back to do');
    head = ChartHead(ShapeInverted(), -1);
    AssertEquals(head.style, InvertedTriangleNoteStyle,
        'a missing inverted triangle falls back to the built-in one');
    head = ChartHead(ShapeHalfCircle(), -1);
    AssertEquals(head.style, ShapedNote2NoteStyle, 'a missing half circle falls back to re');
    head = ChartHead(ShapeCone(), -1);
    AssertEquals(head.style, ShapedNote7NoteStyle, 'a missing cone falls back to ti');

    // Each instrument's own settings.
    options = CreateDictionary('bellHead', 'Normal', 'chimeHead', 'Diamond', 'smbHead', 'Cross',
        'pfHead', 'P', 'whitechapelHead', 'W',
        'bellShape', ShapeMatch(), 'chimeShape', ShapeSquare(), 'smbShape', ShapeTriangle(),
        'pfShape', ShapeCone(), 'whitechapelShape', ShapeInverted());
    AssertEquals(HeadChosen('bells', options), 'Normal', 'the handbell notehead');
    AssertEquals(HeadChosen('chimes', options), 'Diamond', 'the handchime notehead');
    AssertEquals(HeadChosen('smbs', options), 'Cross', 'the SMB notehead');
    AssertEquals(HeadChosen('pf', options), 'P', 'the P&F notehead');
    AssertEquals(HeadChosen('whitechapel', options), 'W', 'the Whitechapel notehead');
    AssertEquals(ShapeChosen('bells', options), ShapeMatch(), 'the handbell shape');
    AssertEquals(ShapeChosen('chimes', options), ShapeSquare(), 'the handchime shape');
    AssertEquals(ShapeChosen('smbs', options), ShapeTriangle(), 'the SMB shape');
    AssertEquals(ShapeChosen('pf', options), ShapeCone(), 'the P&F shape');
    AssertEquals(ShapeChosen('whitechapel', options), ShapeInverted(), 'the Whitechapel shape');

    // The boxes.
    items = ChartShapeItems();
    AssertEquals(items.Length, 8, 'matching and seven shapes');
    AssertEquals(items[0], ShapeMatch(), 'matching comes first');
    AssertEquals(items[1], ShapeRound(), 'then round');
    AssertEquals(items[7], ShapeCone(), 'and the cone last');
    AssertEquals(PreferredShape(ShapeSquare()), ShapeSquare(), 'a remembered shape is kept');
    AssertEquals(PreferredShape('Hexagon'), ShapeMatch(), 'an unknown shape opens on matching');
    AssertEquals(PreferredShape(''), ShapeMatch(), 'nothing remembered opens on matching');
}

// Copies a head in from the notehead file installed beside the plug-in. A
// score cannot lose a notehead style once it has one, so after the first run
// this checks only that the file is found and the score keeps its bars.
TestImportHeads() {
    score = Sibelius.ActiveScore;
    AssertTrue(NoteheadFilePath() != '', 'the notehead file is installed beside the plug-in');

    bars = score.NthStaff(1).BarCount;
    name = ShapeHeadName(ShapeTriangle());
    ImportHeads(score, CreateSparseArray(name));
    AssertTrue(NamedNoteStyle(score, name) >= 0, 'the triangle head is in the score');
    AssertEquals(score.NthStaff(1).BarCount, bars, 'copying a head in leaves the bar count alone');
    active = Sibelius.ActiveScore;
    AssertEquals('' & active.FileName, '' & score.FileName, 'the score is active again afterwards');
}
