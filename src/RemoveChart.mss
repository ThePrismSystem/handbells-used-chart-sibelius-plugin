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
