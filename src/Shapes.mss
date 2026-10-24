// The shapes a chart can be drawn in, and the entry that takes the shape from
// the notehead the music uses. Kept in the manifest with the other text the
// user reads.
ShapeMatch() {
    return '' & SHAPE_MATCH;
}

ShapeRound() {
    return '' & SHAPE_ROUND;
}

ShapeDiamond() {
    return '' & SHAPE_DIAMOND;
}

ShapeSquare() {
    return '' & SHAPE_SQUARE;
}

ShapeTriangle() {
    return '' & SHAPE_TRIANGLE;
}

ShapeInverted() {
    return '' & SHAPE_INVERTED;
}

ShapeCross() {
    return '' & SHAPE_CROSS;
}

// What each Chart Shape box lists, matching first.
ChartShapeItems() {
    return CreateSparseArray(ShapeMatch(), ShapeRound(), ShapeDiamond(), ShapeSquare(),
        ShapeTriangle(), ShapeInverted(), ShapeCross());
}

// The value a Chart Shape box opens on: the last choice, while it is still a
// shape the box lists.
PreferredShape(remembered) {
    if (HeadListed(ChartShapeItems(), remembered) = 1) {
        return remembered;
    }
    return ShapeMatch();
}

// The shape of a notehead, or '' when there is no telling. ManuScript reads a
// notehead as a number and a name, never as a drawing. Sibelius's own styles,
// 0 to 23, are the same shape in every score and every language, so they are
// read by number, up to the last of them, fa with its stem down. One made by
// hand has only its name, and Sibelius names a copy after the head it was
// made from, so the name is read for a shape.
ShapeOfStyle(index, name) {
    if (index >= 0) {
        if (index <= ShapedNote4StemDownNoteStyle) {
            return BuiltInShape(index);
        }
    }
    return NamedShape(name);
}

// The shaped notes run do to ti, so 1 is do's triangle, 3 mi's diamond, 4
// fa's right triangle, in two orientations, and 6 la's square. Re and ti, and
// the slashes, the headless note and the cross-or-diamond, are none of the
// chart shapes.
BuiltInShape(index) {
    if (StyleIn(index, CreateSparseArray(NormalNoteStyle, StemlessNoteStyle, SilentNoteStyle,
        CueNoteStyle, SlashedNoteStyle, BackSlashedNoteStyle, ShapedNote5NoteStyle))) {
        return ShapeRound();
    }
    if (StyleIn(index, CreateSparseArray(DiamondNoteStyle, BlackAndWhiteDiamondNoteStyle,
        ShapedNote3NoteStyle))) {
        return ShapeDiamond();
    }
    if (index = ShapedNote6NoteStyle) {
        return ShapeSquare();
    }
    if (StyleIn(index, CreateSparseArray(ArrowUpNoteStyle, ShapedNote1NoteStyle,
        ShapedNote4StemUpNoteStyle, ShapedNote4StemDownNoteStyle))) {
        return ShapeTriangle();
    }
    if (StyleIn(index, CreateSparseArray(ArrowDownNoteStyle, InvertedTriangleNoteStyle))) {
        return ShapeInverted();
    }
    if (index = CrossNoteStyle) {
        return ShapeCross();
    }
    return '';
}

// Not HeadListed, which reads an empty name as listed nowhere, and the plain
// head is style 0.
StyleIn(index, styles) {
    for i = 0 to styles.Length {
        if (styles[i] = index) {
            return True;
        }
    }
    return False;
}

// English names only, as the copies a localised Sibelius makes are named in
// its own language. An inverted triangle is looked for before a triangle,
// whose name it contains, and round last, because the chart's own heads are
// all named stemless.
NamedShape(name) {
    text = utils.LowerCase('' & name);
    if (TextContains(text, 'inverted')) {
        return ShapeInverted();
    }
    if (TextContains(text, 'triangle')) {
        return ShapeTriangle();
    }
    if (TextContains(text, 'diamond')) {
        return ShapeDiamond();
    }
    if (TextContains(text, 'square')) {
        return ShapeSquare();
    }
    if (TextContains(text, 'cross')) {
        return ShapeCross();
    }
    if ((TextContains(text, 'normal')) or (TextContains(text, 'round')) or (TextContains(text, 'stemless'))) {
        return ShapeRound();
    }
    return '';
}

// The shape a section is drawn in: the one its Chart Shape box names, or the
// shape of the notehead its music uses, or failing both the shape that
// instrument was always charted in.
ChartShape(choice, index, name, kind) {
    if (choice != '') {
        if (choice != ShapeMatch()) {
            return choice;
        }
    }
    shape = ShapeOfStyle(index, name);
    if (shape != '') {
        return shape;
    }
    return DefaultShape(kind);
}

DefaultShape(kind) {
    if (kind = 'chimes') {
        return ShapeDiamond();
    }
    if (kind = 'smbs') {
        return ShapeSquare();
    }
    return ShapeRound();
}

// The stemless head a shape is drawn with, by the name the notehead file gives
// it, or '' for round, whose Stemless head every score has.
ShapeHeadName(shape) {
    if (shape = ShapeRound()) {
        return '';
    }
    return shape & ('' & STEMLESS_SUFFIX);
}

// The head a column is drawn with, as Dictionary{style, tick}, given the index
// the score has for the shape's stemless head, or -1. ManuScript cannot switch
// a stem off, so a shape whose head is missing takes Sibelius's own head of
// that shape and is written as whole notes, which carry no stem at any
// notehead style. It costs the filled head, because a whole note's is hollow.
ChartHead(shape, index) {
    if (ShapeHeadName(shape) = '') {
        return CreateDictionary('style', StemlessNoteStyle, 'tick', 256);
    }
    if (index >= 0) {
        return CreateDictionary('style', index, 'tick', 256);
    }
    return CreateDictionary('style', FallbackStyle(shape), 'tick', 1024);
}

FallbackStyle(shape) {
    if (shape = ShapeDiamond()) {
        return DiamondNoteStyle;
    }
    if (shape = ShapeSquare()) {
        return ShapedNote6NoteStyle;
    }
    if (shape = ShapeTriangle()) {
        return ShapedNote1NoteStyle;
    }
    if (shape = ShapeInverted()) {
        return InvertedTriangleNoteStyle;
    }
    return CrossNoteStyle;
}

// Each instrument's notehead and Chart Shape box.
HeadChosen(kind, options) {
    if (kind = 'chimes') {
        return '' & options.chimeHead;
    }
    if (kind = 'smbs') {
        return '' & options.smbHead;
    }
    if (kind = 'pf') {
        return '' & options.pfHead;
    }
    if (kind = 'whitechapel') {
        return '' & options.whitechapelHead;
    }
    return '' & options.bellHead;
}

ShapeChosen(kind, options) {
    if (kind = 'chimes') {
        return '' & options.chimeShape;
    }
    if (kind = 'smbs') {
        return '' & options.smbShape;
    }
    if (kind = 'pf') {
        return '' & options.pfShape;
    }
    if (kind = 'whitechapel') {
        return '' & options.whitechapelShape;
    }
    return '' & options.bellShape;
}
