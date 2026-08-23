Initialize() {
    EnableStringSafety();
    // 2026 is the only version this targets. Registering on an older release
    // would offer a menu item that fails somewhere deep in the build with no
    // explanation, so it declines to appear at all.
    // Year-based releases encode as YYYY * 10000 + minor * 100 + revision * 10,
    // which is why the guide's own example compares 2020.6 against 20200600.
    // The reference section's major * 1000 formula describes 3.1.3 -> 3130 and
    // does not fit the year releases; it is not the encoding in use here.
    if (Sibelius.ProgramVersion >= 20260000) {
        AddToPluginsMenu('' & _PluginMenuName, 'Run');
    }
}
