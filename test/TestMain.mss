Initialize() {
    EnableStringSafety();
    if (Sibelius.ProgramVersion >= 20260000) {
        AddToPluginsMenu(_PluginMenuName, 'Run');
    }
}

Run() {
    AssertReset();
    SelfTest();
    Sibelius.MessageBox(AssertReport());
    trace(AssertReport());
}

SelfTest() {
    AssertEquals(1, 1, 'one equals one');
    AssertTrue(True, 'true is true');
    AssertEquals(1, 2, 'deliberate failure');
}
