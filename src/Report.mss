ReportSay(kind, text) {
    trace('Handbells Used Chart [' & kind & '] ' & text);
    Sibelius.MessageBox(text);
}

// One branch per warning type, rather than a two-way test that treats anything
// unrecognised as the out-of-range case: that shape reads names on a warning
// that carries none, and a new type would take the whole run down inside the
// code meant to explain a problem.
WarningLines(warnings) {
    lines = '';
    for i = 0 to warnings.Length {
        warning = warnings[i];
        line = '';
        if (warning.type = 'unknown-notehead') {
            line = warning.count & ' note(s) with an unrecognised notehead were skipped';
            // Named only when there is a name to give. A notehead whose style
            // name will not read leaves the count to speak for itself rather
            // than printing an empty list after a colon.
            names = warning.names;
            if (names.Length > 0) {
                line = line & (': ' & JoinNames(names));
            }
        }
        if (warning.type = 'unreadable-pitch') {
            line = warning.count & ' note(s) with an unreadable pitch were skipped';
        }
        if (warning.type = 'out-of-range') {
            line = 'Bells outside C2-C9 were skipped: ' & JoinNames(warning.names);
        }
        // The only warning raised while drawing rather than while planning:
        // whether the score carries the notehead a section wants is not
        // knowable until the chart asks the score for it. Either of the two
        // instruments that use a hand-made head can raise it, so it says which.
        if (warning.type = 'missing-notehead') {
            line = (warning.instrument & ' were drawn as hollow whole notes because ')
                & ('this score has no ' & JoinNames(warning.names)) & ' notehead';
        }
        // The parts warnings. A part has no name ManuScript can read, so it is
        // named by the instruments it holds.
        if (warning.type = 'part-not-charted') {
            line = 'Sibelius would not add the charts to the part for ' & JoinNames(warning.names)
                & ', so that part has none';
        }
        if (warning.type = 'no-part-for-charts') {
            line = 'No part holds a selected instrument, so only the full score has the chart';
        }
        if (warning.type = 'title-not-restored') {
            line = warning.count & ' title or copyright line(s) in the parts could not be put back where they were';
        }
        if (warning.type = 'margin-not-restored') {
            line = warning.count & ' part(s) could not be found to put back the top margin of their first page';
        }
        if (line != '') {
            if (lines != '') {
                lines = lines & '\n';
            }
            lines = lines & line;
        }
    }
    return lines;
}

JoinNames(names) {
    text = '';
    for i = 0 to names.Length {
        if (i > 0) {
            text = text & ', ';
        }
        text = text & names[i];
    }
    return text;
}
