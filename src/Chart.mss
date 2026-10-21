// Returns Dictionary{ok, kind, text}. Does not report anything itself and does
// not touch Redraw or the selection; Run owns both. Apart from Run, so the
// test plug-in can drive a whole run.
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
        if (options.instruments.Length = 0) {
            return CreateDictionary('ok', False, 'kind', 'error',
                'text', '' & _NoInstrumentSelected);
        }
    }

    // Adding chart staves to a part and taking them away both move its title
    // block, and a re-run does both, so each part's is kept from before the
    // removal and put back after the build. The full score's is left to the
    // build and the removal themselves.
    ProbeParts(score, 'start');
    ProbeTitleWrites(score, 'start');
    titles = KeepTitleText(score);
    message = ChartOrRemove(score, options);
    ProbeParts(score, 'built');
    ProbeTitleWrites(score, 'built');
    missed = RestoreTitleText(score, titles);
    ProbeParts(score, 'end');
    if (missed > 0) {
        message.text = WithWarnings(CreateSparseArray(
            CreateDictionary('type', 'title-not-restored', 'count', missed)), message.text);
    }
    return message;
}

ChartOrRemove(score, options) {
    // Removal first, so a re-run replaces its own chart rather than reading it
    // back in and charting the chart.
    removal = RemoveChart(score);
    warnings = CreateSparseArray();
    if (removal.unrestored > 0) {
        warnings.Push(CreateDictionary('type', 'margin-not-restored', 'count', removal.unrestored));
    }
    if (removal.error != '') {
        return CreateDictionary('ok', False, 'kind', 'error', 'text', WithWarnings(warnings, removal.error));
    }

    // H2 again: every Data read is coerced before it goes anywhere. These two
    // are stored into a dictionary and compared against '' back in Run, so an
    // uncoerced read would put a TreeNode where a string is later tested.
    if (options.remove) {
        if (removal.removed) {
            return CreateDictionary('ok', True, 'kind', 'info',
                'text', WithWarnings(warnings, '' & _ChartWasRemoved));
        }
        return CreateDictionary('ok', False, 'kind', 'warning', 'text', '' & _NoChartToRemove);
    }

    plan = BuildChartPlan(ReadScoreNotes(score), options);
    planWarnings = plan.warnings;
    for i = 0 to planWarnings.Length {
        warnings.Push(planWarnings[i]);
    }

    // Warnings are folded into the message ahead of the nothing-to-draw case,
    // not reported after it. A score whose only bells lie outside C2-C9 plans
    // no sections at all, and being told 'no handbells were found' is both
    // wrong and useless when the run knows exactly which bells it skipped.
    if (plan.sections.Length = 0) {
        text = '' & _NoBellsFound;
        if (removal.removed) {
            text = text & ('\n\n' & _ChartWasRemoved);
        }
        return CreateDictionary('ok', False, 'kind', 'warning', 'text', WithWarnings(warnings, text));
    }

    result = DrawCharts(score, plan, options);
    if (not(result.ok)) {
        return CreateDictionary('ok', False, 'kind', 'error', 'text', result.error);
    }

    // The chart's own warnings join the plan's. Whether the score carries the
    // notehead an SMB column wants is only discovered while drawing, so a
    // planning-time list alone would leave that one unreported.
    drawWarnings = result.warnings;
    for i = 0 to drawWarnings.Length {
        warnings.Push(drawWarnings[i]);
    }

    summary = '';
    for i = 0 to plan.sections.Length {
        if (i > 0) {
            summary = summary & '\n';
        }
        summary = summary & plan.sections[i].label;
    }
    if (plan.emptyNames.Length > 0) {
        summary = summary & ('\n' & (('' & _NothingToChartFor) & ' ' & JoinNames(plan.emptyNames)));
    }
    if (removal.removed) {
        summary = summary & ('\n\n' & _ChartWasReplaced);
    }

    return CreateDictionary('ok', True, 'kind', 'info', 'text', WithWarnings(warnings, summary));
}

// The warning lines, if there are any, ahead of the text.
WithWarnings(warnings, text) {
    lines = WarningLines(warnings);
    if (lines = '') {
        return text;
    }
    return (lines & '\n\n') & text;
}
