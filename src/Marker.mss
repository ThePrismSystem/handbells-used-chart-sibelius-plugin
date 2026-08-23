MarkerEncode(sections, totalStaves, columnsArray) {
    text = ('' & MARKER_PREFIX) & '|' & ('' & MARKER_VERSION) & '|' & sections & '|' & totalStaves;
    for i = 0 to columnsArray.Length {
        text = text & '|' & columnsArray[i];
    }
    return text;
}

// Returns null for anything that is not a marker this version wrote. A caller
// that gets null treats the score as carrying no chart; a caller that gets a
// dictionary still has to cross-check it against the score before acting.
MarkerDecode(text) {
    if (text = null) {
        return null;
    }
    parts = SplitOnPipe(text);
    if (parts.Length < 5) {
        return null;
    }
    if (parts[0] != ('' & MARKER_PREFIX)) {
        return null;
    }
    if (parts[1] != ('' & MARKER_VERSION)) {
        return null;
    }

    // utils.IsNumeric with the integer-only flag, rather than coercing with
    // `+ 0`: coercion turns '2 charts' into 2 and garbage into 0, silently
    // accepting a hand-edited marker as a real one.
    if (not(utils.IsNumeric(parts[2], True))) {
        return null;
    }
    if (not(utils.IsNumeric(parts[3], True))) {
        return null;
    }
    sections = 0 + parts[2];
    totalStaves = 0 + parts[3];
    if (sections < 1) {
        return null;
    }
    if (parts.Length != (4 + sections)) {
        return null;
    }

    columns = CreateSparseArray();
    for i = 0 to sections {
        if (not(utils.IsNumeric(parts[4 + i], True))) {
            return null;
        }
        value = 0 + parts[4 + i];
        if (value < 1) {
            return null;
        }
        columns.Push(value);
    }

    return CreateDictionary('sections', sections, 'totalStaves', totalStaves, 'columns', columns);
}

// Substring, not CharAt: CharAt returns a character value rather than a string,
// which compares and concatenates by code point. Substring(text, i, 1) always
// yields a one-character string.
SplitOnPipe(text) {
    parts = CreateSparseArray();
    current = '';
    subject = '' & text;
    for i = 0 to Length(subject) {
        char = Substring(subject, i, 1);
        if (char = '|') {
            parts.Push(current);
            current = '';
        } else {
            current = current & char;
        }
    }
    parts.Push(current);
    return parts;
}

// The marker is a hidden Text object at position 0 of the first chart bar on
// the first chart staff. Searching every staff's bar 1 rather than a recorded
// position, because the recorded position is exactly what is in doubt when
// this is called.
MarkerFind(score) {
    n = 1;
    while (n <= score.StaffCount) {
        bar = score.NthStaff(n).NthBar(1);
        for each Text t in bar {
            if (MarkerDecode(t.Text) != null) {
                return t;
            }
        }
        n = n + 1;
    }
    return null;
}

MarkerWrite(bar, sections, totalStaves, columnsArray) {
    text = bar.AddText(0, MarkerEncode(sections, totalStaves, columnsArray), LabelTextStyle());
    text.Hidden = True;
    return text;
}
