#!/usr/bin/env node
import { copyFileSync, mkdirSync, readdirSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

// The subfolder name becomes the plug-in category in Sibelius's ribbon.
const CATEGORY = 'Handbells';

export function pluginDir(platform, home) {
    if (platform !== 'darwin') {
        throw new Error(
            `Sibelius only runs on macOS and Windows, and this project targets macOS; ` +
            `cannot deploy from ${platform}.`
        );
    }
    return join(home, 'Library/Application Support/Avid/Sibelius/Plugins', CATEGORY);
}

function main() {
    const target = pluginDir(process.platform, homedir());
    mkdirSync(target, { recursive: true });
    for (const name of readdirSync(join(ROOT, 'build'))) {
        if (!name.endsWith('.plg')) continue;
        copyFileSync(join(ROOT, 'build', name), join(target, name));
        console.log(`deployed ${name} -> ${target}`);
    }
    console.log('Restart Sibelius to pick up new or renamed plug-ins.');
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main();
