#!/usr/bin/env node
// Writes Obsidian Web Clipper's settings into the vault in the shape of its
// "Export all settings" button, so "Import all settings" can restore them.
import { cp, mkdtemp, readFile, rename, rm, writeFile } from "node:fs/promises";
import { homedir, tmpdir } from "node:os";
import { join } from "node:path";
import { ClassicLevel } from "classic-level";
import LZString from "lz-string";

const EXTENSION_ID = "cnjifjpddelmedmihgijeibhnjfabmlf";
const STORE = join(homedir(), "Library/Application Support/Arc/User Data/Profile 3/Sync Extension Settings", EXTENSION_ID);
const OUTPUT = join(homedir(), "Work/Vault/.obsidian/web-clipper-settings.json");
const SECRET_KEYS = new Set(["apiKey"]);

// The browser holds the store's lock, so open a copy.
async function readStore() {
  const snapshot = await mkdtemp(join(tmpdir(), "web-clipper-"));
  try {
    await cp(STORE, snapshot, { recursive: true });
    const db = new ClassicLevel(snapshot, { createIfMissing: false });
    const storage = {};
    for await (const [key, value] of db.iterator()) storage[key] = JSON.parse(value);
    await db.close();
    return storage;
  } finally {
    await rm(snapshot, { recursive: true, force: true });
  }
}

function unpackTemplates(settings) {
  for (const templateId of settings.template_list ?? []) {
    const key = `template_${templateId}`;
    if (Array.isArray(settings[key])) {
      settings[key] = JSON.parse(LZString.decompressFromUTF16(settings[key].join("")));
    }
  }
}

const settings = await readStore();
unpackTemplates(settings);
const text = JSON.stringify(settings, (key, value) => (SECRET_KEYS.has(key) ? undefined : value), 2) + "\n";
const current = await readFile(OUTPUT, "utf8").catch(() => null);
if (text !== current) {
  await writeFile(`${OUTPUT}.tmp`, text);
  await rename(`${OUTPUT}.tmp`, OUTPUT);
}
