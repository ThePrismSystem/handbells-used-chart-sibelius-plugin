// The notehead file is a score installed beside the plug-in, holding a note in
// each stemless head a chart can want. ManuScript cannot make a notehead
// style, but a pasted note carries its style into the score it is pasted
// into, which is how a head the score lacks is copied in from the file.
NoteheadFileName() {
    return '' & NOTEHEAD_FILE;
}

PluginFileName() {
    return '' & PLUGIN_FILE;
}

// The file's full path, or '' when it is not installed. It sits beside the
// plug-in, so it is looked for in the folder the plug-in was loaded from,
// whatever category the user named that folder for.
NoteheadFilePath() {
    path = PluginFolderPath();
    if (path = '') {
        return '';
    }
    folder = Sibelius.GetFolder(path);
    if (not(IsObject(folder))) {
        return '';
    }
    for each SIB candidate in folder {
        if (('' & candidate.NameNoPath) = NoteheadFileName()) {
            return '' & candidate.NameWithExt;
        }
    }
    return '';
}

// The folder HandbellsUsedChart.plg was loaded from, or '' when Sibelius lists
// no plug-in loaded from that file. The test plug-in is installed beside it.
// Not utils.GetSibeliusPluginsFolder: a search from it did not find the file
// installed in the user's own plug-in folder.
PluginFolderPath() {
    for each p in Sibelius.Plugins {
        file = p.File;
        if (IsObject(file)) {
            if (('' & file.NameNoPath) = PluginFileName()) {
                return '' & file.Path;
            }
        }
    }
    return '';
}

// Copies each named head in from the notehead file. A head the file lacks is
// skipped, and the caller, looking it up again, falls back from it. Each is
// copied with Sibelius's own clipboard, the only one that reaches another
// score, so whatever the user last copied is replaced.
ImportHeads(score, names) {
    path = NoteheadFilePath();
    if (path = '') {
        return False;
    }

    // A file already open is used as it is and left open, because closing it
    // unsaved would throw away whatever the user has changed in it.
    data = OpenScoreNamed(path);
    opened = False;
    if (data = null) {
        if (not(Sibelius.Open(path, True))) {
            return False;
        }
        opened = True;
        data = Sibelius.ActiveScore;
        // Never the score being charted, which is closed below unsaved.
        if (('' & data.FileName) = ('' & score.FileName)) {
            return False;
        }
    }

    for i = 0 to names.Length {
        nr = NoteRestInHead(data, names[i]);
        if (nr != null) {
            CopyHeadIn(score, data, nr);
        }
    }

    if (opened) {
        Sibelius.CloseAllWindowsForScore(data, False);
    }
    Sibelius.ActiveScore = score;
    return True;
}

OpenScoreNamed(path) {
    for i = 0 to Sibelius.ScoreCount {
        candidate = Sibelius.NthScore(i);
        if (('' & candidate.FileName) = path) {
            return candidate;
        }
    }
    return null;
}

// The first note or chord carrying the named head, or null.
NoteRestInHead(score, name) {
    n = 1;
    while (n <= score.StaffCount) {
        staff = score.NthStaff(n);
        for each NoteRest nr in staff {
            // H3: the notes in a NoteRest are iterated untyped.
            for each note in nr {
                if (('' & note.NoteStyleName) = name) {
                    return nr;
                }
            }
        }
        n = n + 1;
    }
    return null;
}

// The note is pasted into a bar inserted at the end of the score, and the bar
// deleted again, which leaves the head's style behind. A bar is inserted
// before one added for the purpose, because InsertBars needs a bar to go in
// front of. Copying reads the active score's selection and pasting writes to
// the active score, so each side is made active for its half.
CopyHeadIn(score, data, nr) {
    Sibelius.ActiveScore = data;
    selection = data.Selection;
    selection.Clear();
    nr.Select();
    selection.Copy(0);
    selection.Clear();
    length = nr.Duration;
    Sibelius.ActiveScore = score;

    score.AddBars(1);
    last = score.SystemStaff.BarCount;
    lastBar = score.SystemStaff.NthBar(last);
    if (lastBar.Length > length) {
        length = lastBar.Length;
    }
    score.InsertBars(1, last, length);
    pasting = score.Selection;
    pasting.PasteToPosition(1, last, 0, 0);

    system = score.SystemStaff;
    doomed = system.NthBar(system.BarCount);
    doomed.Delete();
    doomed = system.NthBar(system.BarCount);
    doomed.Delete();
    return True;
}
