#!/usr/bin/env node
// Writes Obsidian Web Clipper's settings into the vault in the shape of its
// "Export all settings" button, so "Import all settings" can restore them.
import { access, cp, mkdtemp, readdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import { homedir, tmpdir } from "node:os";
import { join } from "node:path";
import { ClassicLevel } from "classic-level";
import LZString from "lz-string";

if (!process.env.WORK) throw new Error("WORK is not set, run Config/setup.sh");

const EXTENSION_ID = "cnjifjpddelmedmihgijeibhnjfabmlf";
const ARC_PROFILES = join(homedir(), "Library/Application Support/Arc/User Data");
const OUTPUT = join(process.env.WORK, "Vault/.obsidian/web-clipper-settings.json");
const SECRET_KEYS = new Set(["apiKey"]);

// Profile folder names differ per machine, so find the one that has Web Clipper.
async function findStore() {
  const stores = [];
  for (const profile of await readdir(ARC_PROFILES)) {
    const store = join(ARC_PROFILES, profile, "Sync Extension Settings", EXTENSION_ID);
    if (await access(store).then(() => true, () => false)) stores.push(store);
  }
  if (stores.length !== 1) throw new Error(`expected 1 Arc profile with Web Clipper, found ${stores.length}`);
  return stores[0];
}

// The browser holds the store's lock, so open a copy.
async function readStore() {
  const snapshot = await mkdtemp(join(tmpdir(), "web-clipper-"));
  try {
    await cp(await findStore(), snapshot, { recursive: true });
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
