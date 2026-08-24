// Settings come from a dialog, with the last values remembered in Data
// variables between runs. MuseScore read these from score properties instead
// only because a dialog blocks a headless batch run; Sibelius has no headless
// mode, so that constraint does not apply here.
ReadOptions(score) {
    // The two notehead dropdowns are filled from the open score, so this has
    // to run before the dialog is shown rather than being fixed at build time.
    choices = ScoreHeadChoices(score);
    items = HeadChoiceItems(choices.names);

    // A combo box lists the CHILDREN of the TreeNode its list variable holds,
    // and a plug-in's global data is a TreeNode. A sparse array is a different
    // type entirely - Javascript-style, with Length and Push and no children -
    // so assigning one here left both boxes empty with nothing reported.
    // The guide's own list-box example is the shape that works: give the Data
    // variable a fresh CreateArray, then subscript that variable directly.
    // Building the array first and assigning it afterwards is untested and not
    // what the example does, so it is not what this does either.
    // Two arrays rather than one shared between the boxes, because these are
    // the plug-in's own global nodes and nothing documents what handing the
    // same node to two controls means.
    _BellHeadItems = CreateArray();
    _ChimeHeadItems = CreateArray();
    for i = 0 to items.Length {
        name = items[i];
        _BellHeadItems[i] = name;
        _ChimeHeadItems[i] = name;
    }
    dlg_bellHead = PreferredHead(choices.names, '' & dlg_bellHead, choices.defaultBell);
    dlg_chimeHead = PreferredHead(choices.names, '' & dlg_chimeHead, choices.defaultChime);

    if (not(Sibelius.ShowDialog(_SettingsDialog, self))) {
        return null;
    }
    return CreateDictionary(
        'bellLabel', Trim(dlg_bellLabel),
        'chimeLabel', Trim(dlg_chimeLabel),
        'chimeColor', UsableColor(dlg_chimeColor),
        'bellHead', Trim(dlg_bellHead),
        'chimeHead', Trim(dlg_chimeHead),
        'remove', ('' & dlg_remove) = '1'
    );
}

// Trimmed and given its '#' first. The value is whatever a user typed, so
// ' #c00000' and 'c00000' both turn up. An unparseable value is treated as no
// colour at all, leaving the chimes black, rather than failing the run.
UsableColor(value) {
    text = Trim(value);
    if (text = '') {
        return '';
    }
    if (Substring(text, 0, 1) != '#') {
        text = '#' & text;
    }
    if (Length(text) != 7) {
        return '';
    }
    return text;
}

// The Substring calls sit inside the loop rather than in its condition. With
// no documented short-circuiting for `and`, a condition of the form
// `(Length(text) > 0) and (Substring(text, ...) = ' ')` would call Substring
// on an empty string, and the second one with a start index of -1, on the
// pass that empties the text.
Trim(value) {
    text = '' & value;

    trimming = 1;
    while (trimming = 1) {
        if (Length(text) = 0) {
            trimming = 0;
        } else {
            if (Substring(text, 0, 1) = ' ') {
                text = Substring(text, 1);
            } else {
                trimming = 0;
            }
        }
    }

    trimming = 1;
    while (trimming = 1) {
        if (Length(text) = 0) {
            trimming = 0;
        } else {
            if (Substring(text, Length(text) - 1, 1) = ' ') {
                text = Substring(text, 0, Length(text) - 1);
            } else {
                trimming = 0;
            }
        }
    }

    return text;
}
