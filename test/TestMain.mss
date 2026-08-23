Initialize() {
    EnableStringSafety();
    if (Sibelius.ProgramVersion >= 20260000) {
        AddToPluginsMenu(_PluginMenuName, 'Run');
    }
}

Run() {
    AssertReset();
    TestPitch();
    TestBellName();
    TestCollect();
    TestColumns();
    TestColumnsOrphan();
    TestPlan();
    TestMarker();
    TestReadScore();
    TestBuildChart();
    Sibelius.MessageBox(AssertReport());
    trace(AssertReport());
}
