Initialize() {
    EnableStringSafety();
    if (Sibelius.ProgramVersion >= 20260000) {
        AddToPluginsMenu(_PluginMenuName, 'Run');
    }
}

Run() {
    AssertReset();
    TestPitch();
    Sibelius.MessageBox(AssertReport());
    trace(AssertReport());
}
