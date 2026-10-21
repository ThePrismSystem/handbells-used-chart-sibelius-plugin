// ManuScript edits whichever part is current, and a run started while the user
// is looking at a part would hide staves, set breaks and look for a chart in
// that part instead of in the full score. Returns the part to go back to.
EnterFullScore(score) {
    was = score.CurrentDynamicPart;
    parts = score.DynamicParts;
    score.CurrentDynamicPart = parts[0];
    return was;
}

// Everything a run draws: the full-score chart, then, when the parts box is
// ticked, those same chart staves added to the parts that carry them, each
// laid out to show only its own charts. Returns BuildChart's result, with a
// warning for any part that could not be given its charts, and one when the
// box was ticked but no part holds a selected instrument.
DrawCharts(score, plan, options) {
    partPlan = PlanParts(score, plan, options);
    result = BuildChart(score, plan, options);
    if (not(result.ok)) {
        return result;
    }
    if (plan.sections.Length = 0) {
        return result;
    }
    ProbeParts(score, 'after-build');
    firstChartStaff = (score.StaffCount - (plan.sections.Length * 2)) + 1;
    DeleteChartOnlyParts(score, firstChartStaff);
    ProbeParts(score, 'after-delete');
    partWarnings = ApplyParts(score, plan, partPlan.entries, firstChartStaff, options.pageBreak = True);

    warnings = result.warnings;
    for i = 0 to partWarnings.Length {
        warnings.Push(partWarnings[i]);
    }
    if (options.parts = True) {
        if (partPlan.entries.Length = 0) {
            warnings.Push(CreateDictionary('type', 'no-part-for-charts'));
        }
    }
    return result;
}

// Staves first, layout after: a part is laid out once, with every chart staff
// it will carry already in it. A part that refuses one of its staves is given
// none of them and named in a warning, rather than laid out around a chart
// with a staff missing. Returns the warnings.
ApplyParts(score, plan, entries, firstChartStaff, breakForOne) {
    barCount = score.NthStaff(1).BarCount;
    warnings = CreateSparseArray();
    for e = 0 to entries.Length {
        entry = entries[e];
        part = entry.part;
        // Counted before anything is added, so the part's own staves are what
        // the part held rather than what is left after taking away what was
        // meant to be added.
        pieceCount = part.StaveCount;
        carried = entry.sections;
        added = CreateSparseArray();
        complete = 1;
        for k = 0 to carried.Length {
            index = carried[k];
            treble = firstChartStaff + (index * 2);
            if (complete = 1) {
                complete = AddChartStaff(part, score.NthStaff(treble), added);
            }
            if (complete = 1) {
                complete = AddChartStaff(part, score.NthStaff(treble + 1), added);
            }
        }
        if (complete = 1) {
            ProbeLayout(score, part, 'after-add');
            LayOutPart(score, part, plan.sections, carried, pieceCount, barCount, breakForOne);
        } else {
            for a = 0 to added.Length {
                staff = added[a];
                part.DeleteStaffFromPart(staff);
            }
            warnings.Push(CreateDictionary('type', 'part-not-charted', 'names', entry.names));
        }
    }
    return warnings;
}

// 1 when the staff went into the part, which is then listed in added.
AddChartStaff(part, staff, added) {
    if (part.AddStaffToPart(staff)) {
        added.Push(staff);
        return 1;
    }
    return 0;
}

// The same layout BuildChart gives the full score, done again in one part:
// HideEmptyStaves numbers staves and bars within the current part, and hidden
// staves and breaks belong to each part separately, so nothing carries over.
//
// Each of the part's own charts is a system of its own, showing that chart's
// two staves only, and only the upper one for a one-staff instrument, exactly
// as in the full score. A bar of a chart the part does not carry cannot be a
// system of its own: Sibelius keeps one staff showing in every system, so it
// would stand as a lone empty staff. It joins the part's chart beside it
// instead, as a short empty bar. Through the music, the part's chart staves
// are hidden and its own staves are left as the user had them.
//
// The last chart bar ends the page when the part has two or more chart
// sections, or one and breakForOne is set, so the music starts on a page of
// its own laid out as the user laid it out. Adding charts to a full first page
// otherwise pushes music off it, and a part's layout may hold it there
// regardless, overlapping the systems.
//
// The chart staves were added at the bottom of the part in section order, so
// they follow the part's pieceCount staves of its own, two per carried
// section. The breaks go on a staff the part holds: the reference warns that
// editing a staff a part does not hold creates overrides that stay invisible.
LayOutPart(score, part, sections, carried, pieceCount, barCount, breakForOne) {
    chartBars = sections.Length;
    anchor = null;
    for each staff in part {
        if (anchor = null) {
            anchor = staff;
        }
    }
    systems = PartChartSystems(CarriedPositions(chartBars, carried));
    shows = systems.shows;
    ends = systems.ends;

    parts = score.DynamicParts;
    score.CurrentDynamicPart = part;
    staveCount = part.StaveCount;
    endsPage = PartEndsPage(carried.Length, breakForOne);
    for b = 1 to chartBars + 1 {
        if (ends[b - 1] = 1) {
            anchor.NthBar(b).BreakType = EndOfSystemOrPage;
            if (b = chartBars) {
                if (endsPage = 1) {
                    anchor.NthBar(b).BreakType = EndOfPage;
                }
            }
        } else {
            anchor.NthBar(b).BreakType = MiddleOfSystem;
        }
        position = shows[b - 1];
        index = carried[position];
        section = sections[index];
        hidden = ChartBarHiddenStaves(pieceCount, staveCount, position, UsesOneStaff(section.kind));
        for s = 0 to hidden.Length {
            if (hidden[s] = 1) {
                score.HideEmptyStaves(s + 1, s + 1, b, b);
            }
        }
    }
    if (barCount > chartBars) {
        score.HideEmptyStaves(pieceCount + 1, staveCount, chartBars + 1, barCount);
    }
    ProbeLayout(score, part, 'after-hide');
    // The charts' ledger lines reach far past their staves, and the music's
    // first system lost whatever spacing the part had given it when the chart
    // took the first system's place.
    score.OptimizeStaffSpacing(1, staveCount, 1, chartBars + 1);
    ProbeLayout(score, part, 'after-optimize');
    score.CurrentDynamicPart = parts[0];
    return True;
}

// 1 when a part's charts end its first page, 0 when the music may follow them
// on it. Counted in chart sections: bells and chimes for one instrument are
// two systems, and two systems are enough to push music off the first page.
PartEndsPage(carriedCount, breakForOne) {
    if (carriedCount > 1) {
        return 1;
    }
    if (breakForOne) {
        return 1;
    }
    return 0;
}

// Per chart bar, the part's own chart index of that bar's chart, or -1 for a
// chart the part does not carry. carried lists the part's sections in order.
CarriedPositions(chartBars, carried) {
    positions = CreateSparseArray();
    for k = 0 to chartBars {
        positions.Push(-1);
    }
    for j = 0 to carried.Length {
        index = carried[j];
        positions[index] = j;
    }
    return positions;
}

// Which of a part's staves a chart bar hides, top to bottom, 1 for hidden:
// every staff but the two of the chart shown at position among the part's
// own, and its lower staff as well for a one-staff chart. The part's own
// pieceCount staves come first, then two staves per chart it carries.
ChartBarHiddenStaves(pieceCount, staveCount, position, oneStaff) {
    treble = (pieceCount + (position * 2)) + 1;
    flags = CreateSparseArray();
    s = 1;
    while (s <= staveCount) {
        flag = 1;
        if (s = treble) {
            flag = 0;
        }
        if (s = (treble + 1)) {
            if (oneStaff = 0) {
                flag = 0;
            }
        }
        flags.Push(flag);
        s = s + 1;
    }
    return flags;
}

// Which of the part's own charts each chart bar's system shows, and whether
// the bar ends that system. positions holds, per chart bar, the part's own
// chart index or -1 for a chart it does not carry, and at least one is its
// own. A bar it does not carry joins the own chart before it, or the first
// one when none comes before. Returns Dictionary{shows, ends}, ends holding 1
// or 0.
PartChartSystems(positions) {
    shows = CreateSparseArray();
    first = -1;
    previous = -1;
    for k = 0 to positions.Length {
        if (positions[k] >= 0) {
            previous = positions[k];
            if (first < 0) {
                first = previous;
            }
        }
        shows.Push(previous);
    }
    for k = 0 to shows.Length {
        if (shows[k] < 0) {
            shows[k] = first;
        }
    }
    ends = CreateSparseArray();
    last = shows.Length - 1;
    for k = 0 to shows.Length {
        if (k = last) {
            ends.Push(1);
        } else {
            if (shows[k + 1] != shows[k]) {
                ends.Push(1);
            } else {
                ends.Push(0);
            }
        }
    }
    return CreateDictionary('shows', shows, 'ends', ends);
}

// Adding chart staves to a part, or taking them away, puts the part's title
// block back at its styles' default positions, and a part's title block hangs
// from its top staff, so the composer lines landed on the chart. A plug-in
// cannot move it back: Sibelius ignores an offset written in a part. Where the
// part's lines followed the full score's, Sibelius's own Reset to Score
// Position puts them back. The offsets of the text that stays on the first
// page are read in the full score and in every part holding staves before a
// run changes anything. Returns Dictionary{score, parts}: the full score's
// records, and one Dictionary{part, items} per part. The parts are collected
// before any of them is made current, because the collection is not to be
// changed while it is being walked.
KeepTitleText(score) {
    parts = score.DynamicParts;
    found = CreateSparseArray();
    for each part in parts {
        if (not(part.IsFullScore)) {
            if (part.StaveCount > 0) {
                found.Push(part);
            }
        }
    }
    kept = CreateSparseArray();
    for i = 0 to found.Length {
        part = found[i];
        score.CurrentDynamicPart = part;
        kept.Push(CreateDictionary('part', part, 'items', TitleItems(score)));
        score.CurrentDynamicPart = parts[0];
    }
    return CreateDictionary('score', TitleItems(score), 'parts', kept);
}

// The first-page text in the first bar, as the current part or full score has
// it: Dictionary{style, text, n, dx, dy} per item.
TitleItems(score) {
    items = CreateSparseArray();
    seen = CreateSparseArray();
    firstBar = score.SystemStaff.NthBar(1);
    for each item in firstBar {
        if (item.Type = 'SystemTextItem') {
            if (StyleStaysOnFirstPage(item.StyleId)) {
                style = '' & item.StyleId;
                text = '' & item.Text;
                items.Push(CreateDictionary('style', style, 'text', text,
                    'n', TitleOccurrence(seen, style, text), 'dx', item.Dx, 'dy', item.Dy));
            }
        }
    }
    return items;
}

// After the run, in each part, the lines that moved are selected and reset to
// the full score's positions, which a removal leaves where they were. The
// command acts on the part on screen, so each part is shown while it runs.
// Returns how many lines are not back where they were: those the part had
// placed itself, and any the reset did not move.
RestoreTitleText(score, kept) {
    parts = score.DynamicParts;
    entries = kept.parts;
    missed = 0;
    for i = 0 to entries.Length {
        entry = entries[i];
        part = entry.part;
        // A part holding nothing but chart staves is deleted with them.
        if (IsValid(part)) {
            score.CurrentDynamicPart = part;
            selection = score.Selection;
            selection.Clear();
            reset = 0;
            lost = 0;
            seen = CreateSparseArray();
            firstBar = score.SystemStaff.NthBar(1);
            for each item in firstBar {
                if (item.Type = 'SystemTextItem') {
                    if (StyleStaysOnFirstPage(item.StyleId)) {
                        style = '' & item.StyleId;
                        text = '' & item.Text;
                        n = TitleOccurrence(seen, style, text);
                        action = TitleRestoreAction(TitleRecordFor(entry.items, style, text, n),
                            TitleRecordFor(kept.score, style, text, n), item.Dx, item.Dy);
                        if (action = 'reset') {
                            item.Select();
                            reset = reset + 1;
                        }
                        if (action = 'lost') {
                            lost = lost + 1;
                        }
                    }
                }
            }
            // Counted again after a reset, which takes in the lost lines.
            if (reset > 0) {
                Sibelius.ShowDynamicPart(part);
                Sibelius.Execute(Cmd('Reset to Score Position'));
                selection.Clear();
                missed = missed + MovedTitleCount(score, entry.items);
                ProbeLayout(score, part, 'after-reset ' & reset);
            } else {
                missed = missed + lost;
            }
            score.CurrentDynamicPart = parts[0];
        }
    }
    return missed;
}

// How many first-page lines in the current part are not where items records
// them.
MovedTitleCount(score, items) {
    moved = 0;
    seen = CreateSparseArray();
    firstBar = score.SystemStaff.NthBar(1);
    for each item in firstBar {
        if (item.Type = 'SystemTextItem') {
            if (StyleStaysOnFirstPage(item.StyleId)) {
                style = '' & item.StyleId;
                text = '' & item.Text;
                was = TitleRecordFor(items, style, text, TitleOccurrence(seen, style, text));
                if (was != null) {
                    if ((item.Dx != was.dx) or (item.Dy != was.dy)) {
                        moved = moved + 1;
                    }
                }
            }
        }
    }
    return moved;
}

// What a part's first-page line needs after a run: 'keep' when it is where it
// was, or was not there before; 'reset' when it moved but had followed the
// full score, so the full score's position is its own; 'lost' when it moved
// from a place the part gave it, which nothing can put back. was and fullScore
// are its records from before the run, in the part and in the full score.
TitleRestoreAction(was, fullScore, dx, dy) {
    if (was = null) {
        return 'keep';
    }
    if ((dx = was.dx) and (dy = was.dy)) {
        return 'keep';
    }
    if (fullScore = null) {
        return 'lost';
    }
    if ((was.dx = fullScore.dx) and (was.dy = fullScore.dy)) {
        return 'reset';
    }
    return 'lost';
}

// The items are found again after the run rather than held across it, so
// each is known by its style and text, and by how many like it came first.
// Counts this one into seen and returns its number, from 1.
TitleOccurrence(seen, style, text) {
    count = 1;
    for i = 0 to seen.Length {
        other = seen[i];
        if ((other.style = style) and (other.text = text)) {
            count = count + 1;
        }
    }
    seen.Push(CreateDictionary('style', style, 'text', text));
    return count;
}

// The kept record for the nth item of this style and text, or null.
TitleRecordFor(records, style, text, n) {
    for i = 0 to records.Length {
        record = records[i];
        if ((record.style = style) and (record.text = text)) {
            if (record.n = n) {
                return record;
            }
        }
    }
    return null;
}

// Sibelius gives each instrument the plug-in adds a part of its own, the way
// it does for an instrument added by hand, which would leave a part per chart
// section that nobody asked for. A part holding nothing but chart staves is
// one of those. A part the user made, holding a chart staff alongside their
// own, is left alone. Collected first and deleted after, as the guide requires
// of any collection being changed.
DeleteChartOnlyParts(score, firstChartStaff) {
    parts = score.DynamicParts;
    counter = 0;
    for each part in parts {
        if (not(part.IsFullScore)) {
            if (part.StaveCount > 0) {
                chartOnly = 1;
                for each staff in part {
                    if (staff.StaffNum < firstChartStaff) {
                        chartOnly = 0;
                    }
                }
                if (chartOnly = 1) {
                    name = 'chartpart' & counter;
                    @name = part;
                    counter = counter + 1;
                }
            }
        }
    }

    while (counter > 0) {
        counter = counter - 1;
        name = 'chartpart' & counter;
        part = @name;
        parts.DeletePart(part);
    }
    return True;
}

// Which part carries which chart, worked out before anything is drawn, because
// the labels a section gets depend on it. Returns Dictionary{entries}, one
// entry per part that carries anything. With the parts box unticked no part is
// considered at all, so every section keeps its one full-score label.
//
// Only parts that hold staves: a part left holding nothing is no one's part.
PlanParts(score, plan, options) {
    infos = CreateSparseArray();
    if (options.parts = True) {
        parts = score.DynamicParts;
        for each part in parts {
            if (not(part.IsFullScore)) {
                if (part.StaveCount > 0) {
                    infos.Push(CreateDictionary('part', part,
                        'names', PartInstrumentNames(score, part, options.instruments)));
                }
            }
        }
    }
    return CreateDictionary('entries', PlanPartEntries(plan.sections, infos));
}

// The selected instruments with at least one staff in the part. A part may
// hold several instruments, and an instrument may sit in several parts.
PartInstrumentNames(score, part, instruments) {
    names = CreateSparseArray();
    for i = 0 to instruments.Length {
        instrument = instruments[i];
        inside = 0;
        n = instrument.firstStaff;
        while (n <= instrument.lastStaff) {
            if (part.IncludesStaff(score.NthStaff(n))) {
                inside = 1;
            }
            n = n + 1;
        }
        if (inside = 1) {
            names.Push(instrument.name);
        }
    }
    return names;
}

// Pure, so it can be tested with strings standing in for parts. partInfos is
// Dictionary{part, names} per part, and each entry carries both on.
//
// It also marks each section's splitLabel. A label sits on a chart staff that
// the full score and every part holding it share, so a section can only read
// differently in the parts by carrying two labels, one shown in the score and
// one in the parts. That is wanted when the full-score label names the
// instrument and every part carrying the section is one choir's part. A part
// holding several choirs needs the names to tell its charts apart, and one
// staff cannot be plain in one part and named in another, so a section in any
// such part keeps its named label everywhere.
PlanPartEntries(sections, partInfos) {
    inPart = CreateSparseArray();
    named = CreateSparseArray();
    for i = 0 to sections.Length {
        inPart.Push(0);
        named.Push(0);
    }

    entries = CreateSparseArray();
    for p = 0 to partInfos.Length {
        info = partInfos[p];
        carried = PartSections(sections, info.names);
        if (carried.Length > 0) {
            entries.Push(CreateDictionary('part', info.part,
                'names', info.names, 'sections', carried));
            several = 0;
            if (DistinctOwnerCount(sections, carried) > 1) {
                several = 1;
            }
            for k = 0 to carried.Length {
                index = carried[k];
                inPart[index] = 1;
                if (several = 1) {
                    named[index] = 1;
                }
            }
        }
    }

    for i = 0 to sections.Length {
        section = sections[i];
        split = 0;
        if (inPart[i] = 1) {
            if (named[i] = 0) {
                if (section.label != section.plainLabel) {
                    split = 1;
                }
            }
        }
        section._property:splitLabel = split;
    }
    return entries;
}

// The indexes of the sections belonging to any of the named instruments.
PartSections(sections, partNames) {
    carried = CreateSparseArray();
    for i = 0 to sections.Length {
        section = sections[i];
        owners = section.owners;
        hit = 0;
        for j = 0 to owners.Length {
            if (HeadListed(partNames, owners[j]) = 1) {
                hit = 1;
            }
        }
        if (hit = 1) {
            carried.Push(i);
        }
    }
    return carried;
}

DistinctOwnerCount(sections, indexes) {
    seen = CreateDictionary();
    count = 0;
    for k = 0 to indexes.Length {
        index = indexes[k];
        section = sections[index];
        owners = section.owners;
        for j = 0 to owners.Length {
            name = '' & owners[j];
            if (seen[name] = null) {
                seen[name] = 1;
                count = count + 1;
            }
        }
    }
    return count;
}

// Diagnostic, kept until the squashed music pages in parts are understood: a
// part's music came out squashed from its first music page on, on some runs
// and not others. One part's systems per page and title offsets, read in the
// part's own context.
ProbeLayout(score, part, label) {
    was = score.CurrentDynamicPart;
    score.CurrentDynamicPart = part;
    setup = score.DocumentSetup;
    rules = score.EngravingRules;
    top = score.NthStaff(1);
    line = ('[layout probe] ' & label) & (' part [' & top.FullInstrumentName) & (('] staves=' & part.StaveCount));
    line = line & (' top=' & setup.AboveTopStaveGap) & (' top2=' & setup.AboveTopStaveGapAfterFirstPage);
    line = line & (' auto-optimize=' & score.AutoOptimizeEnabled) & (' justify=' & rules.StaffJustificationPercentage);
    line = line & (' pages=' & score.PageCount) & ' systems=';
    p = 1;
    while ((p <= score.PageCount) and (p <= 8)) {
        if (p > 1) {
            line = line & ',';
        }
        line = line & score.SystemCount(p);
        p = p + 1;
    }
    firstBar = score.SystemStaff.NthBar(1);
    for each item in firstBar {
        if (item.Type = 'SystemTextItem') {
            if (StyleIsPageAligned(item.StyleId)) {
                line = line & ((' ' & Substring('' & item.StyleId, 25)) & ('=' & item.Dx) & (',' & item.Dy));
            }
        }
    }
    trace(line);
    score.CurrentDynamicPart = was;
    return True;
}

// Diagnostic: the full score, then every part holding staves. Collected first,
// as KeepTitleText does.
ProbeParts(score, label) {
    parts = score.DynamicParts;
    found = CreateSparseArray();
    for each part in parts {
        if (not(part.IsFullScore)) {
            if (part.StaveCount > 0) {
                found.Push(part);
            }
        }
    }
    ProbeLayout(score, parts[0], label);
    for i = 0 to found.Length {
        ProbeLayout(score, found[i], label);
    }
    return True;
}
