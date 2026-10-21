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

    // Before the dialog, because filling it already reads the score: the
    // instrument list and the existing chart are looked for in whichever part
    // is current. The part that was current is made current again on every
    // exit below.
    was = EnterFullScore(score);
    options = ReadOptions(score);
    if (options = null) {
        score.CurrentDynamicPart = was;
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
    // Unless the run deleted it: a part holding nothing but chart staves goes
    // with the chart. Shown as well, because putting a part's title block back
    // shows that part.
    if (IsValid(was)) {
        score.CurrentDynamicPart = was;
        Sibelius.ShowDynamicPart(was);
    }

    if (message.text != '') {
        ReportSay(message.kind, message.text);
    }
    return message.ok;
}
