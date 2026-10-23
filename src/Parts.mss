// ManuScript edits whichever part is current, and a run started while the user
// is looking at a part would hide staves, set breaks and look for a chart in
// that part instead of in the full score. Returns the part to go back to.
EnterFullScore(score) {
    was = score.CurrentDynamicPart;
    parts = score.DynamicParts;
    score.CurrentDynamicPart = parts[0];
    return was;
}

// Everything a run draws: the full-score chart and, when the parts box is
// ticked, a copy of each chart on its owners' staves, shown in the parts
// alone; then each part that carries a chart is laid out to show only its
// own. Returns BuildChart's result, with a warning naming any instrument
// whose staves could not hold a copy, and one when the box was ticked but no
// part holds a selected instrument.
DrawCharts(score, plan, options) {
    partPlan = PlanParts(score, plan, options);
    result = BuildChart(score, plan, options);
    if (not(result.ok)) {
        return result;
    }
    if (plan.sections.Length = 0) {
        return result;
    }
    firstChartStaff = (score.StaffCount - (plan.sections.Length * 2)) + 1;
    DeleteChartOnlyParts(score, firstChartStaff);
    LayOutParts(score, plan, partPlan.entries, options.pageBreak = True);

    // A part whose instruments could not hold a copy is named for that, rather
    // than as a part holding no selected instrument, which it does.
    warnings = result.warnings;
    skipped = partPlan.skipped;
    if (skipped.Length > 0) {
        warnings.Push(CreateDictionary('type', 'no-copy-for-instrument', 'names', skipped));
    }
    if (options.parts = True) {
        if ((partPlan.entries.Length = 0) and (skipped.Length = 0)) {
            warnings.Push(CreateDictionary('type', 'no-part-for-charts'));
        }
    }
    return result;
}

// Each part that carries a chart is laid out in its own view. Returns True.
LayOutParts(score, plan, entries, breakForOne) {
    for e = 0 to entries.Length {
        entry = entries[e];
        LayOutPart(score, entry.part, plan.sections, entry.sections, breakForOne);
    }
    return True;
}

// The same layout BuildChart gives the full score, done again in one part:
// HideEmptyStaves numbers staves and bars within the current part, and hidden
// staves and breaks belong to each part separately, so nothing carries over.
//
// Each of the part's own charts is a system of its own, showing the staves
// holding that chart's copy and no others. A bar of a chart the part does not
// carry would stand as a lone empty staff if it were a system of its own,
// since Sibelius keeps one staff showing in every system. Unless every staff
// of the part is No instrument (hidden) there, which HideOutsideCopies makes
// a staff wherever it holds no copy: then there is no staff left to show, and
// a run of such bars is a system of its own that draws nothing. A part with a
// staff holding no copy has one left, so the bar joins the part's chart
// beside it instead, as a short empty bar.
//
// The last chart bar ends the page when the part has two or more chart
// sections, or one and breakForOne is set, so the music starts on a page of
// its own laid out as the user laid it out. Adding charts to a full first page
// otherwise pushes music off it, and a part's layout may hold it there
// regardless, overlapping the systems.
//
// The breaks go on a staff the part holds: the reference warns that editing a
// staff a part does not hold creates overrides that stay invisible. The size
// change is made here, in the part, because one made in the full score does
// not reach it. Spacing is optimised over the chart bars alone, so the
// music's own spacing is the part's as it was.
LayOutPart(score, part, sections, carried, breakForOne) {
    chartBars = sections.Length;
    staffNums = PartStaffNumbers(part);
    anchor = null;
    for each staff in part {
        if (anchor = null) {
            anchor = staff;
        }
    }
    positions = CarriedPositions(chartBars, carried);
    systems = PartChartSystems(positions);
    shows = systems.shows;
    vanishing = PartVanishingBars(staffNums, sections, chartBars);
    breaks = PartBarBreaks(positions, vanishing);

    parts = score.DynamicParts;
    score.CurrentDynamicPart = part;
    staveCount = part.StaveCount;
    endsPage = PartEndsPage(carried.Length, breakForOne);
    shown = CreateSparseArray();
    for s = 0 to staveCount {
        shown.Push(0);
    }
    for b = 1 to chartBars + 1 {
        // The last chart bar always ends a system, so the page break can
        // take its place.
        breakType = breaks[b - 1];
        if ((b = chartBars) and (endsPage = 1)) {
            breakType = EndOfPage;
        }
        anchor.NthBar(b).BreakType = breakType;
        if (vanishing[b - 1] = 0) {
            position = shows[b - 1];
            index = carried[position];
            hidden = PartBarHiddenStaves(staffNums, SectionCopyStaves(sections[index]));
            for s = 0 to hidden.Length {
                if (hidden[s] = 1) {
                    score.HideEmptyStaves(s + 1, s + 1, b, b);
                } else {
                    shown[s] = 1;
                }
            }
        }
    }
    // 2 is SmallSize in the reference's list of staff sizes.
    for s = 0 to shown.Length {
        if (shown[s] = 1) {
            score.NthStaff(s + 1).ScaleFactorChange(2, 1, chartBars);
        }
    }
    score.OptimizeStaffSpacing(1, staveCount, 1, chartBars);
    score.CurrentDynamicPart = parts[0];
    return True;
}

// The full-score numbers of a part's staves, in the part's order. Read while
// the full score is current, which is what makes them full-score numbers.
PartStaffNumbers(part) {
    nums = CreateSparseArray();
    for each staff in part {
        nums.Push(staff.StaffNum);
    }
    return nums;
}

// Which of a part's staves a chart bar hides, top to bottom, 1 for hidden:
// every staff but those holding the shown chart's copies. partStaffNums and
// shownStaves are full-score staff numbers.
PartBarHiddenStaves(partStaffNums, shownStaves) {
    flags = CreateSparseArray();
    for i = 0 to partStaffNums.Length {
        flag = 1;
        for j = 0 to shownStaves.Length {
            if (shownStaves[j] = partStaffNums[i]) {
                flag = 0;
            }
        }
        flags.Push(flag);
    }
    return flags;
}

// Every staff holding one of a section's copies.
SectionCopyStaves(section) {
    staves = CreateSparseArray();
    copies = section.copies;
    for j = 0 to copies.Length {
        copyStaves = copies[j];
        for k = 0 to copyStaves.Length {
            staves.Push(copyStaves[k]);
        }
    }
    return staves;
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

// The chart bars, 1-based, in which a staff holds a copy. sections carry the
// copies PlanCopies gave them.
CopyBarsOfStaff(sections, staffNum) {
    bars = CreateSparseArray();
    for i = 0 to sections.Length {
        section = sections[i];
        copies = section._property:copies;
        held = 0;
        if (copies != null) {
            for j = 0 to copies.Length {
                staves = copies[j];
                for k = 0 to staves.Length {
                    if (staves[k] = staffNum) {
                        held = 1;
                    }
                }
            }
        }
        if (held = 1) {
            bars.Push(i + 1);
        }
    }
    return bars;
}

// Per chart bar, 1 where a staff holding copies in copyBars is No instrument
// (hidden): every chart bar in which it holds none. A staff holding no copy
// is never hidden.
StaffHiddenBars(copyBars, chartBars) {
    flags = CreateSparseArray();
    for b = 1 to chartBars + 1 {
        flag = 0;
        if (copyBars.Length > 0) {
            flag = 1;
            for i = 0 to copyBars.Length {
                if (copyBars[i] = b) {
                    flag = 0;
                }
            }
        }
        flags.Push(flag);
    }
    return flags;
}

// Per chart bar, 1 where every one of a part's staves is No instrument
// (hidden), so the part has nothing to show there. partStaffNums are
// full-score staff numbers.
PartVanishingBars(partStaffNums, sections, chartBars) {
    flags = CreateSparseArray();
    for b = 0 to chartBars {
        flags.Push(1);
    }
    for s = 0 to partStaffNums.Length {
        hidden = StaffHiddenBars(CopyBarsOfStaff(sections, partStaffNums[s]), chartBars);
        for b = 0 to chartBars {
            if (hidden[b] = 0) {
                flags[b] = 0;
            }
        }
    }
    return flags;
}

// Per chart bar, the break a part gives it. Each run of bars the part loses
// is a system of its own, which draws nothing, so the chart after it starts a
// system of its own with clefs at its head. The rest are laid out by
// PartChartSystems as if the lost bars were not there at all. positions are
// as CarriedPositions gives them.
PartBarBreaks(positions, vanishing) {
    kept = CreateSparseArray();
    for k = 0 to positions.Length {
        if (vanishing[k] = 0) {
            kept.Push(positions[k]);
        }
    }
    systems = PartChartSystems(kept);
    ends = systems.ends;
    breaks = CreateSparseArray();
    j = 0;
    for k = 0 to positions.Length {
        if (vanishing[k] = 1) {
            // Nested, not joined with and: the guide documents no
            // short-circuiting, and the last bar has no next one to read.
            runEnds = 1;
            if (k < (positions.Length - 1)) {
                if (vanishing[k + 1] = 1) {
                    runEnds = 0;
                }
            }
            if (runEnds = 1) {
                breaks.Push(EndOfSystemOrPage);
            } else {
                breaks.Push(MiddleOfSystem);
            }
        } else {
            if (ends[j] = 1) {
                breaks.Push(EndOfSystemOrPage);
            } else {
                breaks.Push(MiddleOfSystem);
            }
            j = j + 1;
        }
    }
    return breaks;
}

// True when a bar holds an instrument change at its start.
HasInstrumentChange(bar) {
    for each InstrumentChange change in bar {
        if (change.Position = 0) {
            return True;
        }
    }
    return False;
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
// the copies a build draws and the labels they read depend on it. Returns
// Dictionary{entries, skipped}: one entry per part that carries anything, and
// the names of instruments in a part whose staves could not hold a copy. With
// the parts box unticked no part is considered at all, so nothing is copied.
//
// Only parts that hold staves: a part left holding nothing is no one's part.
PlanParts(score, plan, options) {
    infos = CreateSparseArray();
    held = CreateSparseArray();
    if (options.parts = True) {
        parts = score.DynamicParts;
        for each part in parts {
            if (not(part.IsFullScore)) {
                if (part.StaveCount > 0) {
                    names = PartInstrumentNames(score, part, options.instruments);
                    infos.Push(CreateDictionary('part', part, 'names', names));
                    for i = 0 to names.Length {
                        if (HeadListed(held, names[i]) = 0) {
                            held.Push(names[i]);
                        }
                    }
                }
            }
        }
    }
    skipped = PlanCopies(score, plan.sections, options.instruments, held);
    return CreateDictionary('entries', PlanPartEntries(plan.sections, infos), 'skipped', skipped);
}

// A part shows a chart as a copy drawn on its owner's own staves, shown only
// in the parts, because adding the chart's own staves to a part resets the
// part's title block and staff spacing. Marks every section with copyOwners,
// the owners in held whose staves can hold a copy, and copies, the staves of
// each, in the same order. Returns the owners in held whose staves cannot.
PlanCopies(score, sections, instruments, held) {
    skipped = CreateSparseArray();
    for i = 0 to sections.Length {
        section = sections[i];
        owners = section.owners;
        copyOwners = CreateSparseArray();
        copies = CreateSparseArray();
        for j = 0 to owners.Length {
            name = owners[j];
            if (HeadListed(held, name) = 1) {
                instrument = InstrumentNamed(instruments, name);
                staves = CopyStaves(instrument.firstStaff, instrument.lastStaff, UsesOneStaff(section.kind),
                    StaffPitchedFlags(score, instrument.firstStaff, instrument.lastStaff));
                if (staves.Length > 0) {
                    copyOwners.Push(name);
                    copies.Push(staves);
                } else {
                    if (HeadListed(skipped, name) = 0) {
                        skipped.Push(name);
                    }
                }
            }
        }
        section._property:copyOwners = copyOwners;
        section._property:copies = copies;
    }
    return skipped;
}

// The staves an owner's copy goes on: its top two, or its top one for a
// one-staff chart. None when it has too few, or when one of them is not a
// five-line pitched staff, which pitched marks with 1 per staff from the
// first. A two-staff chart's bars are sized for two staves and shared with
// the full score, so there is no fitting it onto one.
CopyStaves(firstStaff, lastStaff, oneStaff, pitched) {
    staves = CreateSparseArray();
    need = 2;
    if (oneStaff = 1) {
        need = 1;
    }
    if (((lastStaff - firstStaff) + 1) < need) {
        return staves;
    }
    for k = 0 to need {
        if (pitched[k] != 1) {
            return CreateSparseArray();
        }
        staves.Push(firstStaff + k);
    }
    return staves;
}

// 1 per staff from firstStaff to lastStaff when it is a five-line pitched
// staff, which is what a chart is drawn on, and 0 for percussion, tab or any
// other number of lines.
StaffPitchedFlags(score, firstStaff, lastStaff) {
    flags = CreateSparseArray();
    n = firstStaff;
    while (n <= lastStaff) {
        type = score.NthStaff(n).InitialInstrumentType;
        flag = 0;
        if ((type.Category = 0) and (type.NumStaveLines = 5)) {
            flag = 1;
        }
        flags.Push(flag);
        n = n + 1;
    }
    return flags;
}

InstrumentNamed(instruments, name) {
    for i = 0 to instruments.Length {
        instrument = instruments[i];
        if (instrument.name = name) {
            return instrument;
        }
    }
    return null;
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
// It also marks each section's splitLabel: 1 when the parts read the plain
// label rather than the full score's named one. The parts read the label on
// a copy, which sits on its owner's staff in every part holding that staff.
// Plain is wanted when every part carrying the section is one choir's part. A
// part holding several choirs needs the names to tell its charts apart, and
// one staff cannot be plain in one part and named in another, so a section in
// any such part is named in every part.
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

// The indexes of the sections any of the named instruments holds a copy of.
PartSections(sections, partNames) {
    carried = CreateSparseArray();
    for i = 0 to sections.Length {
        section = sections[i];
        owners = section.copyOwners;
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
        owners = section.copyOwners;
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
