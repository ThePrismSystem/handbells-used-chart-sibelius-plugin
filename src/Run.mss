Run() {
    // Ed Hirschman's guard clauses: a plugin should never fail ungracefully.
    // ScoreCount catches Sibelius running with no score open at all, which
    // ActiveScore alone does not.
    if (Sibelius.ScoreCount = 0) {
        Sibelius.MessageBox('' & _ScoreError);
        return False;
    }

    score = Sibelius.ActiveScore;
    if (score.StaffCount = 0) {
        Sibelius.MessageBox('' & _ScoreError);
        return False;
    }

    options = ReadOptions(score);
    if (options = null) {
        return False;
    }

    selection = score.Selection;
    selection.StoreCurrentSelection();
    // H10: the cheapest speedup available. Every branch below must restore it,
    // including the early returns, or the score stops repainting.
    score.Redraw = False;

    // Every exit path below runs through here, so Redraw and the selection are
    // restored exactly once no matter which branch ends the run. Doing it with
    // a return in each branch is how one of them eventually gets missed and
    // leaves the user's score frozen.
    message = ChartScore(score, options);

    score.Redraw = True;
    selection.RestoreSelection();

    if (message.text != '') {
        ReportSay(message.kind, message.text);
    }
    return message.ok;
}

// Returns Dictionary{ok, kind, text}. Does not report anything itself and does
// not touch Redraw or the selection; Run owns both.
ChartScore(score, options) {
    // Ahead of the removal, so a score that would chart nothing useful keeps
    // the chart it has. A removal run never reads a note, so the choice of
    // noteheads cannot block one.
    if (not(options.remove)) {
        duplicate = DuplicateHead(options);
        if (duplicate != '') {
            return CreateDictionary('ok', False, 'kind', 'error',
                'text', ('More than one instrument is set to the ' & duplicate)
                    & (' notehead. ' & _SameNoteheadChosen));
        }
    }

    // Removal first, so a re-run replaces its own chart rather than reading it
    // back in and charting the chart.
    removal = RemoveChart(score);
    if (removal.error != '') {
        return CreateDictionary('ok', False, 'kind', 'error', 'text', removal.error);
    }

    // H2 again: every Data read is coerced before it goes anywhere. These two
    // are stored into a dictionary and compared against '' back in Run, so an
    // uncoerced read would put a TreeNode where a string is later tested.
    if (options.remove) {
        if (removal.removed) {
            return CreateDictionary('ok', True, 'kind', 'info', 'text', '' & _ChartWasRemoved);
        }
        return CreateDictionary('ok', False, 'kind', 'warning', 'text', '' & _NoChartToRemove);
    }

    plan = BuildPlan(ReadScoreNotes(score), options);

    // Warnings are folded into the message ahead of the nothing-to-draw case,
    // not reported after it. A score whose only bells lie outside C2-C9 plans
    // no sections at all, and being told 'no handbells were found' is both
    // wrong and useless when the run knows exactly which bells it skipped.
    if (plan.sections.Length = 0) {
        text = '' & _NoBellsFound;
        if (removal.removed) {
            text = text & ('\n\n' & _ChartWasRemoved);
        }
        lines = WarningLines(plan.warnings);
        if (lines != '') {
            text = (lines & '\n\n') & text;
        }
        return CreateDictionary('ok', False, 'kind', 'warning', 'text', text);
    }

    result = BuildChart(score, plan, options);
    if (not(result.ok)) {
        return CreateDictionary('ok', False, 'kind', 'error', 'text', result.error);
    }

    // The chart's own warnings join the plan's. Whether the score carries the
    // notehead an SMB column wants is only discovered while drawing, so a
    // planning-time list alone would leave that one unreported.
    warnings = plan.warnings;
    for i = 0 to result.warnings.Length {
        warnings.Push(result.warnings[i]);
    }
    lines = WarningLines(warnings);

    summary = '';
    for i = 0 to plan.sections.Length {
        if (i > 0) {
            summary = summary & '\n';
        }
        summary = summary & plan.sections[i].label;
    }
    if (removal.removed) {
        summary = summary & ('\n\n' & _ChartWasReplaced);
    }
    if (lines != '') {
        summary = (lines & '\n\n') & summary;
    }

    return CreateDictionary('ok', True, 'kind', 'info', 'text', summary);
}
