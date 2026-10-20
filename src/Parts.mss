// ManuScript edits whichever part is current, and a run started while the user
// is looking at a part would hide staves, set breaks and look for a chart in
// that part instead of in the full score. Returns the part to go back to.
EnterFullScore(score) {
    was = score.CurrentDynamicPart;
    parts = score.DynamicParts;
    score.CurrentDynamicPart = parts[0];
    return was;
}

// Everything a run draws: the full-score chart exactly as it has always been
// drawn, then, when the parts box is ticked, those same chart staves added to
// the parts that carry them, each laid out to show only its own charts.
// Returns BuildChart's result.
DrawCharts(score, plan, options) {
    partPlan = PlanParts(score, plan, options);
    // Diagnostic, kept until charts are seen in parts: a run with the parts box
    // ticked left every part without its chart, while the test suite drawing
    // the same kind of plan into the same score passed.
    trace('[parts probe] parts=' & options.parts & ' view=' & Sibelius.GetCurrentScoreViewType()
        & ' entries=' & partPlan.entries.Length);
    result = BuildChart(score, plan, options);
    if (not(result.ok)) {
        return result;
    }
    if (plan.sections.Length = 0) {
        return result;
    }
    firstChartStaff = (score.StaffCount - (plan.sections.Length * 2)) + 1;
    DeleteChartOnlyParts(score, firstChartStaff);
    TraceParts(score, 'after delete');
    ApplyParts(score, plan, partPlan, firstChartStaff);
    TraceParts(score, 'after layout');
    return result;
}

// Staves first, layout after: a part is laid out once, with every chart staff
// it will carry already in it. LayOutPart leaves alone any part that carries
// none.
ApplyParts(score, plan, partPlan, firstChartStaff) {
    barCount = score.NthStaff(1).BarCount;

    entries = partPlan.entries;
    for e = 0 to entries.Length {
        entry = entries[e];
        part = entry.part;
        carried = entry.sections;
        for k = 0 to carried.Length {
            index = carried[k];
            treble = firstChartStaff + (index * 2);
            added = part.AddStaffToPart(score.NthStaff(treble));
            trace('[parts probe] entry ' & e & ' add ' & treble & ' = ' & added);
            added = part.AddStaffToPart(score.NthStaff(treble + 1));
            trace('[parts probe] entry ' & e & ' add ' & (treble + 1) & ' = ' & added);
        }
    }

    parts = score.DynamicParts;
    for each part in parts {
        if (not(part.IsFullScore)) {
            if (part.StaveCount > 0) {
                LayOutPart(score, part, plan.sections, firstChartStaff, barCount);
            }
        }
    }
    return True;
}

// The same layout BuildChart gives the full score, done again in one part:
// HideEmptyStaves numbers staves and bars within the current part, and hidden
// staves and breaks belong to each part separately, so nothing carries over.
//
// Each chart bar is a system of its own. In a bar of one of this part's
// charts, everything but that chart's two staves is hidden, and its lower
// staff too for a one-staff instrument, exactly as in the full score. In a bar
// of a chart the part does not carry, every staff is hidden. Through the
// music, the part's chart staves are hidden and its own staves are left as the
// user had them.
//
// The chart staves were added at the bottom of the part in section order, so
// they follow its own staves, two per carried section. Which sections it
// carries, and the staff the breaks go on, are read while the full score is
// still current, where staff numbers mean what BuildChart meant by them. The
// breaks go on a staff the part holds: the reference warns that editing a
// staff a part does not hold creates overrides that stay invisible.
LayOutPart(score, part, sections, firstChartStaff, barCount) {
    chartBars = sections.Length;
    carried = CreateSparseArray();
    positions = CreateSparseArray();
    for k = 0 to chartBars {
        positions.Push(-1);
        if (part.IncludesStaff(score.NthStaff(firstChartStaff + (k * 2)))) {
            positions[k] = carried.Length;
            carried.Push(k);
        }
    }
    // A part with none of the chart's staves is left exactly as a full-score
    // chart has always left it, so a run without parts changes no part at
    // all. What such a part shows for the chart bars is for a session in
    // Sibelius to establish before anything is done about it.
    if (carried.Length = 0) {
        return False;
    }
    anchor = null;
    for each staff in part {
        if (anchor = null) {
            anchor = staff;
        }
    }
    pieceCount = part.StaveCount - (carried.Length * 2);

    parts = score.DynamicParts;
    score.CurrentDynamicPart = part;
    active = score.CurrentDynamicPart;
    trace('[parts probe] layout: staves=' & part.StaveCount & ' piece=' & pieceCount
        & ' carried=' & carried.Length & ' active is full score=' & active.IsFullScore
        & ' active StaffCount=' & score.StaffCount);
    for b = 1 to chartBars + 1 {
        anchor.NthBar(b).BreakType = EndOfSystemOrPage;
        position = positions[b - 1];
        if (position < 0) {
            score.HideEmptyStaves(1, part.StaveCount, b, b);
        } else {
            treble = (pieceCount + (position * 2)) + 1;
            if (pieceCount > 0) {
                score.HideEmptyStaves(1, pieceCount, b, b);
            }
            if (treble > (pieceCount + 1)) {
                score.HideEmptyStaves(pieceCount + 1, treble - 1, b, b);
            }
            if ((treble + 1) < part.StaveCount) {
                score.HideEmptyStaves(treble + 2, part.StaveCount, b, b);
            }
            section = sections[b - 1];
            if (UsesOneStaff(section.kind) = 1) {
                score.HideEmptyStaves(treble + 1, treble + 1, b, b);
            }
        }
    }
    if (carried.Length > 0) {
        if (barCount > chartBars) {
            score.HideEmptyStaves(pieceCount + 1, part.StaveCount, chartBars + 1, barCount);
        }
    }
    TraceLayout(score, anchor, chartBars + 1);
    score.CurrentDynamicPart = parts[0];
    return True;
}

// Diagnostic, read in the part's own context: each chart bar and the first
// music bar, with the break the part sees there and which of its staves are
// hidden (1) or showing (0).
TraceLayout(score, anchor, lastBar) {
    b = 1;
    while (b <= lastBar) {
        line = '';
        s = 1;
        while (s <= score.StaffCount) {
            hidden = 0;
            if (score.NthStaff(s).NthBar(b).OnHiddenStave) {
                hidden = 1;
            }
            line = line & (' ' & hidden);
            s = s + 1;
        }
        trace('[parts probe] bar ' & b & ' break=' & score.NthStaff(1).NthBar(b).BreakType
            & ' anchor break=' & anchor.NthBar(b).BreakType & ' hidden=' & line);
        b = b + 1;
    }
    return True;
}

// Diagnostic: every part and the full-score numbers of the staves it holds.
TraceParts(score, label) {
    parts = score.DynamicParts;
    i = 0;
    for each part in parts {
        line = '';
        for each staff in part {
            line = line & (' ' & staff.StaffNum);
        }
        trace('[probe] part ' & label & ' ' & i & ' fullScore=' & part.IsFullScore & ' staves=' & line);
        i = i + 1;
    }
    return True;
}

// Sibelius may give each instrument the plug-in adds a part of its own, the
// way it does for an instrument added by hand, which would leave a part per
// chart section that nobody asked for. A part holding nothing but chart staves
// is one of those. A part the user made, holding a chart staff alongside their
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
// Dictionary{part, names} per part.
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
            entries.Push(CreateDictionary('part', info.part, 'sections', carried));
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
