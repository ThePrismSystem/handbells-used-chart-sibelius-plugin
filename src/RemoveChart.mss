IdentificationError(reason) {
    return reason & ' Delete the chart staves and their bars in Sibelius, then run this again.';
}

FindChart(score) {
    marker = MarkerFind(score);
    if (marker = null) {
        return CreateDictionary('found', False, 'sections', 0,
            'firstStaff', 0, 'columns', CreateSparseArray(), 'error', '');
    }

    recorded = MarkerDecode(marker.Text);
    unidentifiable = IdentificationError('This score records a Handbells Used chart, '
        & 'but a staff or a bar has been added, removed or moved since, so the chart '
        & 'can no longer be identified.');

    if (recorded.totalStaves != score.StaffCount) {
        return FindFailure(unidentifiable);
    }

    // Below 2, not below 1. A firstStaff of 1 leaves no piece behind the chart,
    // and ShowEmptyStaves(1, 0, ...) would then be handed an inverted 1-based
    // range that the reference does not define. BuildChart cannot produce it,
    // so it only arrives from a hand-edited marker, which is exactly the case
    // this branch exists to refuse.
    firstStaff = (score.StaffCount - (recorded.sections * 2)) + 1;
    if (firstStaff < 2) {
        return FindFailure(unidentifiable);
    }

    n = firstStaff;
    while (n <= score.StaffCount) {
        staff = score.NthStaff(n);
        if (staff.InitialStyleId != ChartInstrument()) {
            return FindFailure(unidentifiable);
        }
        if (staff.NumStavesInSameInstrument != 2) {
            return FindFailure(unidentifiable);
        }
        n = n + 1;
    }

    // The recorded bar lengths settle it. A chart bar was sized to its own
    // column count and nothing else has reason to match.
    for i = 0 to recorded.sections {
        bar = score.NthStaff(1).NthBar(i + 1);
        if (bar = null) {
            return FindFailure(unidentifiable);
        }
        // Either tick is legitimate: a chimes section falls back to whole notes
        // when the score has no stemless diamond, so the same column count can
        // have been sized at 256 or at 1024. Accepting both is what keeps a
        // chart identifiable on a machine whose notehead set differs from the
        // one that built it.
        columnTicks = recorded.columns[i];
        if (bar.Length != (columnTicks * 256)) {
            if (bar.Length != (columnTicks * 1024)) {
                return FindFailure(unidentifiable);
            }
        }
    }

    return CreateDictionary('found', True, 'sections', recorded.sections,
        'firstStaff', firstStaff, 'columns', recorded.columns, 'error', '');
}

FindFailure(message) {
    return CreateDictionary('found', False, 'sections', 0,
        'firstStaff', 0, 'columns', CreateSparseArray(), 'error', message);
}

RemoveChart(score) {
    found = FindChart(score);
    if (found.error != '') {
        return CreateDictionary('removed', False, 'error', found.error);
    }
    if (not(found.found)) {
        return CreateDictionary('removed', False, 'error', '');
    }

    // Staves the chart hid come back before the ranges stop meaning anything.
    pieceStaves = found.firstStaff - 1;
    score.ShowEmptyStaves(1, pieceStaves, 1, found.sections);
    score.ShowEmptyStaves(found.firstStaff, score.StaffCount,
        found.sections + 1, score.NthStaff(1).BarCount);

    // Before any bar goes, rescue the title block it is carrying and drop the
    // renumbering that only made sense while the chart was in front.
    RelocateSystemText(score, found.sections, found.sections + 1, False);
    ClearHiddenBarNumber(score.NthStaff(1).NthBar(found.sections + 1));

    // Bars first: removing the staves renumbers everything underneath us. The
    // marker goes with the bar that holds it.
    barsBefore = score.NthStaff(1).BarCount;
    for i = 0 to found.sections {
        score.NthStaff(1).NthBar(1).Delete();
    }
    if (score.NthStaff(1).BarCount != (barsBefore - found.sections)) {
        return CreateDictionary('removed', False, 'error', IdentificationError(
            'This score records a Handbells Used chart, but Sibelius did not remove '
            & 'the chart bars.'));
    }

    // Bottom-up, so deleting one staff does not renumber the ones still to go.
    staffCountBefore = score.StaffCount;
    n = score.StaffCount;
    while (n >= found.firstStaff) {
        utils.DeleteStaff(score, n, False);
        n = n - 1;
    }
    if (score.StaffCount != (staffCountBefore - (found.sections * 2))) {
        return CreateDictionary('removed', False, 'error', IdentificationError(
            'This score records a Handbells Used chart, but Sibelius did not remove '
            & 'the chart staves.'));
    }

    return CreateDictionary('removed', True, 'error', '');
}

// Both paths relocate system text out of the chart bars, for opposite reasons,
// so they share one routine.
//
// `musicalOnly` decides whether the page-aligned title block travels. On a
// build it must not: the title belongs at the top of the page, above the
// chart, which is where Sibelius already leaves it. On a removal it must,
// because the bar holding it is about to be deleted.
//
// The delete follows the guide's documented shape: collect every item first,
// then delete in REVERSE order. Deleting forwards while iterating desyncs the
// iterator, which is why an earlier attempt left the originals in place and
// added copies beside them, doubling the title block.
RelocateSystemText(score, fromBars, targetBarNum, musicalOnly) {
    system = score.SystemStaff;
    target = system.NthBar(targetBarNum);

    b = 1;
    while (b <= fromBars) {
        bar = system.NthBar(b);

        counter = 0;
        for each item in bar {
            if (item.Type = 'SystemTextItem') {
                take = True;
                if (musicalOnly) {
                    if (StyleIsPageAligned(item.StyleId)) {
                        take = False;
                    }
                }
                if (take) {
                    name = 'moved' & counter;
                    @name = item;
                    counter = counter + 1;
                }
            }
        }

        // Re-add before deleting: an item's properties are only readable while
        // the item is still in the score.
        i = 0;
        while (i < counter) {
            name = 'moved' & i;
            item = @name;
            copy = target.AddText(0, '' & item.Text, '' & item.StyleId);
            if (IsObject(copy)) {
                // Assigned again, because AddText flattens a line break: a
                // composer field reading 'NAME' over 'Arranged by NAME' came
                // back as one line. Text is read/write, so setting it on the
                // finished object puts the break back.
                copy.Text = '' & item.Text;
                PlaceMovedText(copy, item);
            }
            i = i + 1;
        }

        while (counter > 0) {
            counter = counter - 1;
            name = 'moved' & counter;
            item = @name;
            item.Delete();
        }

        b = b + 1;
    }
    return True;
}

// A page-aligned item is positioned against the page, and its offsets were
// measured from the system about to be deleted, so carrying them over put the
// title and subtitle off the top of the page. Its own style knows better.
//
// Everything else is staff-relative, and a staff is a staff in either bar, so
// the vertical nudge still means what it meant. It is worth keeping: two tempo
// texts separated only by their Dy land on top of each other without it.
// Horizontal is left at the default, which for a musical direction is the
// start of the bar, and that is where it belongs.
PlaceMovedText(copy, item) {
    // Before anything else. A full score hides the part-name and header items
    // that only belong in the parts, and a recreated item defaults to visible,
    // which is where a spurious 'Full Score' came from.
    copy.Hidden = item.Hidden;

    if (StyleIsPageAligned(item.StyleId)) {
        copy.ResetPosition();
        return True;
    }
    copy.Dy = item.Dy;
    return True;
}

// ManuScript has no substring search, so this is a scan. The title block
// styles are the `text.system.page_aligned.*` family: title, subtitle,
// composer, copyright and the two instrument-name headers.
StyleIsPageAligned(styleId) {
    text = '' & styleId;
    needle = 'page_aligned';
    limit = Length(text) - Length(needle);
    if (limit < 0) {
        return False;
    }
    for i = 0 to limit + 1 {
        if (Substring(text, i, Length(needle)) = needle) {
            return True;
        }
    }
    return False;
}

// The other half of NumberFromFirstMusicBar. The chart bars' own number
// changes go with the bars, but the one restarting the piece at 1 sits in a
// bar that survives, and leaving it means the plugin did not put the score
// back as it found it.
//
// Only hidden ones go. A visible bar number change in that bar is the user's,
// not the plugin's, and a score that legitimately restarts its numbering there
// must keep doing so. Same reverse-order delete the guide requires.
ClearHiddenBarNumber(bar) {
    counter = 0;
    for each BarNumber bn in bar {
        if (bn.Hidden) {
            name = 'barnum' & counter;
            @name = bn;
            counter = counter + 1;
        }
    }

    while (counter > 0) {
        counter = counter - 1;
        name = 'barnum' & counter;
        bn = @name;
        bn.Delete();
    }
    return True;
}
