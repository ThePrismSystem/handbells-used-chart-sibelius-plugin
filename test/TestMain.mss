Initialize() {
    EnableStringSafety();
    if (Sibelius.ProgramVersion >= 20260000) {
        AddToPluginsMenu('' & _PluginMenuName, 'Run');
    }
}

Run() {
    Diagnose();
    AssertReset();
    TestPitch();
    TestBellName();
    TestCollect();
    TestColumns();
    TestColumnsOrphan();
    TestPlan();
    TestMarker();
    TestOptions();
    TestReport();
    TestReadScore();
    TestBuildChart();
    TestRemoveChart();
    Sibelius.MessageBox(AssertReport());
    trace(AssertReport());
}
