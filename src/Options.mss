// Settings come from a dialog, with the last values remembered in Data
// variables between runs. MuseScore read these from score properties instead
// only because a dialog blocks a headless batch run; Sibelius has no headless
// mode, so that constraint does not apply here.
ReadOptions(score) {
    // The notehead dropdowns are filled from the open score, so this has to
    // run before the dialog is shown rather than being fixed at build time.
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
    // One array per box rather than one shared between them, because these are
    // the plug-in's own global nodes and nothing documents what handing the
    // same node to several controls means.
    _BellHeadItems = CreateArray();
    _ChimeHeadItems = CreateArray();
    _SmbHeadItems = CreateArray();
    for i = 0 to items.Length {
        name = items[i];
        _BellHeadItems[i] = name;
        _ChimeHeadItems[i] = name;
        _SmbHeadItems[i] = name;
    }
    dlg_bellHead = PreferredHead(choices.names, '' & dlg_bellHead, choices.defaultBell);
    dlg_chimeHead = PreferredHead(choices.names, '' & dlg_chimeHead, choices.defaultChime);
    // No fallback of its own: nothing in a score says which notehead means a
    // silver melody bell the way a plain head means a handbell, so an
    // unremembered SMB box opens on no notehead rather than on a guess.
    dlg_smbHead = PreferredHead(choices.names, '' & dlg_smbHead, '');

    // Probe, until the parts checkpoint: the list box is new, its .msd block is
    // written by hand to mirror ComboBox's undocumented shape, and nothing
    // documents whether a multi-select box can open with items selected or
    // what its variable holds afterwards. Charting ignores all three new
    // controls until those answers are in.
    names = InstrumentNames(ScoreInstruments(score));
    _InstrumentItems = CreateArray();
    dlg_instruments = CreateArray();
    for i = 0 to names.Length {
        _InstrumentItems[i] = names[i];
        dlg_instruments[i] = names[i];
    }
    trace('[dialog probe] items offered = ' & names.Length);
    _ChartModeItems = CreateArray();
    _ChartModeItems[0] = '' & CHART_MODE_COMBINED;
    _ChartModeItems[1] = '' & CHART_MODE_SEPARATE;
    if (('' & dlg_chartMode) = '') {
        dlg_chartMode = '' & CHART_MODE_COMBINED;
    }

    if (not(Sibelius.ShowDialog(_SettingsDialog, self))) {
        return null;
    }

    // One statement per read, so a run-time error names the read that failed.
    trace('[dialog probe] value = [' & ('' & dlg_instruments) & ']');
    trace('[dialog probe] NumChildren = ' & dlg_instruments.NumChildren);
    count = dlg_instruments.NumChildren;
    for i = 0 to count {
        trace('[dialog probe] item ' & i & ' = [' & dlg_instruments[i] & ']');
    }

    return CreateDictionary(
        'chimeColor', UsableColor(dlg_chimeColor),
        'smbColor', UsableColor(dlg_smbColor),
        'bellHead', Trim(dlg_bellHead),
        'chimeHead', Trim(dlg_chimeHead),
        'smbHead', Trim(dlg_smbHead),
        'remove', ('' & dlg_remove) = '1'
    );
}

// Called by the list box on every click. A probe for now: whether the call
// arrives while the dialog is open, whether the variable already holds the new
// selection when it does, and whether the Charts box can be greyed out live.
InstrumentsChanged() {
    count = dlg_instruments.NumChildren;
    trace('[dialog probe] changed: NumChildren = ' & count);
    Sibelius.EnableControlById(Self, _SettingsDialog, 'dlg_chartMode', count > 1);
    return True;
}

// The instrument selection is remembered as the names left out, not the names
// chosen, so an instrument the plug-in has never seen starts selected and a
// first run charts everything, as the plug-in always has. Stored as one
// pipe-joined string, because a plain string is the Data variable shape every
// other remembered setting already round-trips through.
PipeList(text) {
    value = '' & text;
    if (value = '') {
        return CreateSparseArray();
    }
    return SplitOnPipe(value);
}

JoinPipe(names) {
    text = '';
    for i = 0 to names.Length {
        if (i > 0) {
            text = text & '|';
        }
        text = text & names[i];
    }
    return text;
}

PreselectedNames(offered, excluded) {
    chosen = CreateSparseArray();
    for i = 0 to offered.Length {
        if (HeadListed(excluded, offered[i]) = 0) {
            chosen.Push(offered[i]);
        }
    }
    return chosen;
}

// What to remember after a run. A name this score does not offer keeps
// whatever was remembered about it, so leaving the piano out of one score
// still leaves it out of the next score that has one. A name it does offer is
// remembered as left out exactly when it was not selected this time.
ExcludedAfterRun(remembered, offered, selected) {
    excluded = CreateSparseArray();
    for i = 0 to remembered.Length {
        if (HeadListed(offered, remembered[i]) = 0) {
            excluded.Push(remembered[i]);
        }
    }
    for i = 0 to offered.Length {
        if (HeadListed(selected, offered[i]) = 0) {
            excluded.Push(offered[i]);
        }
    }
    return excluded;
}

// The notehead two instruments share, or '' when they share none. Two
// instruments cannot use one head: every note carrying it would belong to
// both, and charting each of them twice is not a reading worth guessing at.
// The no-notehead entry is exempt, because any number of instruments may be
// absent from a piece.
DuplicateHead(options) {
    heads = CreateSparseArray(options.bellHead, options.chimeHead, options.smbHead);
    for i = 0 to heads.Length {
        head = '' & heads[i];
        if (head != '') {
            if (head != NoNoteHead()) {
                for j = i + 1 to heads.Length {
                    if (heads[j] = head) {
                        return head;
                    }
                }
            }
        }
    }
    return '';
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
