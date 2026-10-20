// Not assertions: a probe of how a chart behaves in Sibelius parts, run by
// hand once before any of the parts feature is built. Whether chart staves can
// be added to a part, whether breaks and hidden staves are per part, and what
// a part shows for a chart bar that is not its own cannot be settled from the
// reference, and each guess would cost a session.
//
// It builds a two-section chart, one section from each of the first two
// instruments, puts each section into that instrument's part, and leaves it
// all in place to be looked at. Every line it traces starts with [probe].
ProbeParts() {
    score = Sibelius.ActiveScore;
    if (score = null) {
        trace('[probe] open a score first');
        return False;
    }
    parts = score.DynamicParts;
    full = parts[0];
    was = score.CurrentDynamicPart;
    trace('[probe] start: full score = ' & was.IsFullScore & ' viewing part = ' & score.IsDynamicPart);
    score.CurrentDynamicPart = full;

    n = 1;
    while (n <= score.StaffCount) {
        staff = score.NthStaff(n);
        trace('[probe] staff ' & n & ' name=[' & staff.InstrumentName & '] full=['
            & staff.FullInstrumentName & '] span=' & staff.NumStavesInSameInstrument);
        n = n + 1;
    }
    instruments = ScoreInstruments(score);
    for i = 0 to instruments.Length {
        instrument = instruments[i];
        trace('[probe] instrument ' & instrument.name & ' ' & instrument.firstStaff
            & '-' & instrument.lastStaff);
    }

    TraceParts(score, 'before');
    partsBefore = parts.NumChildren;

    found = FindChart(score);
    if ((found.found) or (found.error != '')) {
        trace('[probe] the score already carries a chart; remove it first. Stopping.');
        return ProbeStop(score, was);
    }
    if (instruments.Length < 2) {
        trace('[probe] needs two instruments. Stopping.');
        return ProbeStop(score, was);
    }
    first = instruments[0];
    second = instruments[1];

    choices = ScoreHeadChoices(score);
    options = CreateDictionary('chimeColor', '', 'smbColor', '',
        'bellHead', choices.defaultBell, 'chimeHead', choices.defaultChime,
        'smbHead', NoNoteHead());
    records = ReadScoreNotes(score);
    planA = BuildPlan(RecordsForInstruments(records, CreateSparseArray(first)), options);
    planB = BuildPlan(RecordsForInstruments(records, CreateSparseArray(second)), options);
    if (planA.sections.Length = 0) {
        trace('[probe] the first instrument has nothing to chart. Stopping.');
        return ProbeStop(score, was);
    }
    if (planB.sections.Length = 0) {
        trace('[probe] the second instrument has nothing to chart. Stopping.');
        return ProbeStop(score, was);
    }
    plan = CreateDictionary('sections', CreateSparseArray(planA.sections[0], planB.sections[0]),
        'warnings', CreateSparseArray());

    result = BuildChart(score, plan, options);
    trace('[probe] build ok=' & result.ok & ' error=' & result.error);
    if (not(result.ok)) {
        return ProbeStop(score, was);
    }
    TraceParts(score, 'after build');
    trace('[probe] parts before=' & partsBefore & ' after=' & parts.NumChildren);

    firstChart = (score.StaffCount - 4) + 1;
    partA = PartHoldingStaff(score, first.firstStaff);
    partB = PartHoldingStaff(score, second.firstStaff);
    if (partA = null) {
        trace('[probe] the first instrument has no part. Stopping.');
        return ProbeStop(score, was);
    }
    if (partB = null) {
        trace('[probe] the second instrument has no part. Stopping.');
        return ProbeStop(score, was);
    }

    added = partA.AddStaffToPart(score.NthStaff(firstChart));
    trace('[probe] add ' & firstChart & ' to A = ' & added);
    added = partA.AddStaffToPart(score.NthStaff(firstChart + 1));
    trace('[probe] add ' & (firstChart + 1) & ' to A = ' & added);
    added = partB.AddStaffToPart(score.NthStaff(firstChart + 2));
    trace('[probe] add ' & (firstChart + 2) & ' to B = ' & added);
    added = partB.AddStaffToPart(score.NthStaff(firstChart + 3));
    trace('[probe] add ' & (firstChart + 3) & ' to B = ' & added);
    TraceParts(score, 'after add');

    // Part A only. Part B is left alone, so between them the two parts show
    // what hiding does and what a part shows for a chart bar untouched.
    score.CurrentDynamicPart = partA;
    staffOne = score.NthStaff(1);
    bar2 = staffOne.NthBar(2);
    breakBefore = bar2.BreakType;
    trace('[probe] in A: StaffCount=' & score.StaffCount & ' staff1=[' & staffOne.InstrumentName
        & '] bar2 break=' & breakBefore & ' multirests=' & score.ShowMultiRests);

    // Set, read back from the full score, then put back, so the break test
    // leaves nothing behind to confuse what the part is then seen to show.
    bar2.BreakType = MiddleOfSystem;
    trace('[probe] in A: bar2 break set, reads ' & bar2.BreakType);
    score.CurrentDynamicPart = full;
    trace('[probe] in score: bar2 break=' & score.NthStaff(1).NthBar(2).BreakType);
    score.CurrentDynamicPart = partA;
    bar2 = score.NthStaff(1).NthBar(2);
    bar2.BreakType = breakBefore;

    score.HideEmptyStaves(1, partA.StaveCount, 2, 2);
    s = 1;
    while (s <= partA.StaveCount) {
        trace('[probe] in A bar2 hidden: ' & s & '=' & score.NthStaff(s).NthBar(2).OnHiddenStave);
        s = s + 1;
    }
    score.CurrentDynamicPart = full;

    // Each on a bar or staff of its own, so none sits on top of another or
    // on top of a section label.
    bassA = score.NthStaff(firstChart + 1).NthBar(1);
    dashData = bassA.AddText(0, 'Dash from data: [' & ('' & LABEL_DASH_PROBE) & ']', LabelTextStyle());
    trace('[probe] text dash data = ' & IsObject(dashData));
    bassB = score.NthStaff(firstChart + 3).NthBar(2);
    dashChr = bassB.AddText(0, 'Dash from Chr: [' & Chr(8211) & ']', LabelTextStyle());
    trace('[probe] text dash Chr = ' & IsObject(dashChr));
    trebleA = score.NthStaff(firstChart).NthBar(1);
    scoreOnly = trebleA.AddText(trebleA.Length - 256, 'SCORE ONLY', LabelTextStyle());
    trace('[probe] text score only = ' & IsObject(scoreOnly));
    if (IsObject(scoreOnly)) {
        scoreOnly.ShowInScore();
    }
    trebleB = score.NthStaff(firstChart + 2).NthBar(2);
    partsOnly = trebleB.AddText(trebleB.Length - 256, 'PARTS ONLY', LabelTextStyle());
    trace('[probe] text parts only = ' & IsObject(partsOnly));
    if (IsObject(partsOnly)) {
        partsOnly.ShowInParts();
    }

    score.CurrentDynamicPart = was;
    Sibelius.MessageBox('Parts probe finished. Follow the checklist, then remove the chart with Remove Existing Chart in the main plug-in.');
    return True;
}

ProbeStop(score, was) {
    score.CurrentDynamicPart = was;
    Sibelius.MessageBox('Parts probe stopped. The trace window says why.');
    return False;
}

// The first part, other than the full score, holding the given staff, or null
// when no part does.
PartHoldingStaff(score, staffNum) {
    staff = score.NthStaff(staffNum);
    parts = score.DynamicParts;
    for each part in parts {
        if (not(part.IsFullScore)) {
            if (part.IncludesStaff(staff)) {
                return part;
            }
        }
    }
    return null;
}
