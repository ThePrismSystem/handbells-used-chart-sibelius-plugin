Initialize() {
    EnableStringSafety();
    if (Sibelius.ProgramVersion >= 20260000) {
        AddToPluginsMenu('' & _PluginMenuName, 'Run');
    }
}

Run() {
    // The integration tests build and remove a real chart on the open score.
    // Removing a chart deletes its bars, and the score's title block lives in
    // the bar the chart is built in front of, so it goes with them. Run these
    // on a scratch copy, never on work you care about.
    Sibelius.MessageBox('These tests modify the open score. Use a scratch copy.');
    // The probe builds a chart and leaves it in place to be looked at, and the
    // tests below remove any chart they find, so the two never share a run.
    if (Sibelius.YesNoMessageBox('Run the parts probe instead of the tests?')) {
        ProbeParts();
        return True;
    }
    Diagnose();
    AssertReset();
    TestPitch();
    TestBellName();
    TestCollect();
    TestColumns();
    TestColumnsOrphan();
    TestColumnsSingleStaff();
    TestPlan();
    TestInstruments();
    TestMarker();
    TestOptions();
    TestReport();
    TestNoteHeads();
    TestReadScore();
    TestScoreInstruments();
    TestNoteHeadScan();
    TestBuildChart();
    TestRemoveChart();
    Sibelius.MessageBox(AssertReport());
    trace(AssertReport());
}
