// The notehead styles a score actually uses, read out for the dialog's two
// dropdowns. Bells are not always plain and chimes are not always diamonds:
// a score arranged with any other notehead charted nothing at all until the
// user could say which head means which.
//
// This runs before the chart is removed, so it skips the chart's own staves.
// Without that, a re-run would offer the chart's noteheads back as if the
// music used them, and the stemless diamond it draws chimes with is exactly
// the kind of head a user would then pick by mistake.
ScoreHeadChoices(score) {
    names = CreateSparseArray();
    seen = CreateDictionary();
    // Carried in a dictionary rather than returned from ScanBarHeads because
    // ManuScript passes objects by reference and numbers by value; the scan
    // has to write into something the caller still holds.
    defaults = CreateDictionary('bell', '', 'chime', '');

    lastStaff = score.StaffCount;
    found = FindChart(score);
    if (found.found) {
        lastStaff = found.firstStaff - 1;
    }

    selection = score.Selection;
    if (selection.IsPassage) {
        for each Bar bar in selection {
            // H6: a selected default barline comes back as a Bar rather than a
            // BarObject, and touching it crashes the plugin.
            if (IsObject(bar)) {
                staff = bar.ParentStaff;
                if (staff.StaffNum <= lastStaff) {
                    ScanBarHeads(bar, names, seen, defaults);
                }
            }
        }
    } else {
        n = 1;
        while (n <= lastStaff) {
            staff = score.NthStaff(n);
            b = 1;
            while (b <= staff.BarCount) {
                ScanBarHeads(staff.NthBar(b), names, seen, defaults);
                b = b + 1;
            }
            n = n + 1;
        }
    }

    return CreateDictionary('names', names,
        'defaultBell', defaults.bell, 'defaultChime', defaults.chime);
}

ScanBarHeads(bar, names, seen, defaults) {
    for each NoteRest nr in bar {
        // H3: `for each Note n in nr` does not work. Notes inside a NoteRest
        // must be iterated untyped.
        for each n in nr {
            name = '' & n.NoteStyleName;
            if (name != '') {
                if (seen[name] = null) {
                    // 1, not True: H7 aside, a presence marker in a dictionary
                    // has no reason to be a Boolean, and the lint rules read a
                    // Boolean stored in a collection as a mistake.
                    seen[name] = 1;
                    names.Push(name);
                }
                // The display names of the built-in styles are not documented
                // and a localised Sibelius spells them differently, so the two
                // suggested defaults are found by index and reported by name.
                // Written through _property:, which the guide says never
                // raises at run time, rather than through plain dot
                // assignment, which does when the property is not there yet.
                if (n.NoteStyle = NormalNoteStyle) {
                    defaults._property:bell = name;
                }
                if (n.NoteStyle = DiamondNoteStyle) {
                    defaults._property:chime = name;
                }
            }
        }
    }
    return True;
}

// 1 or 0 rather than True or False: the result is compared with = in both
// callers and the suite asserts on it, and a Boolean would read back as the
// string 'true' through the same coercion every other value here goes through.
HeadListed(names, name) {
    if (name = '') {
        return 0;
    }
    for i = 0 to names.Length {
        if (names[i] = name) {
            return 1;
        }
    }
    return 0;
}

// The value a dropdown opens on. What the user chose last run wins, but only
// while this score still uses that notehead, because the choice is remembered
// in a Data variable and the next score may be someone else's arrangement.
// Failing that it is whichever head the score's own plain or diamond notes
// suggest, and failing that nothing at all: guessing at a head the score never
// pointed to is how a bells-only score ends up charting its bells twice.
PreferredHead(names, remembered, fallback) {
    if (HeadListed(names, remembered) = 1) {
        return remembered;
    }
    if (HeadListed(names, fallback) = 1) {
        return fallback;
    }
    return NoNoteHead();
}

// What the dropdowns actually show: the no-notehead entry first, then every
// head the score uses. Both boxes read the same list, because a score offers
// one set of heads and it is only the choice within it that differs.
HeadChoiceItems(names) {
    items = CreateSparseArray(NoNoteHead());
    for i = 0 to names.Length {
        items.Push(names[i]);
    }
    return items;
}
