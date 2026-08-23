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
    Sibelius.MessageBox(AssertReport());
    trace(AssertReport());
}
