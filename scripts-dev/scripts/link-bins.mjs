#!/usr/bin/env node
// npm 不会把根包自己的 bin 链进 node_modules/.bin，postinstall 时手动链，
// 之后即可用 npx build / npx watch / npx try / npx new。
import { mkdirSync, symlinkSync, chmodSync, rmSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const binDir = join(root, "node_modules", ".bin");
mkdirSync(binDir, { recursive: true });

for (const name of ["build", "watch", "try", "new"]) {
  const link = join(binDir, name);
  rmSync(link, { force: true });
  symlinkSync(join("..", "..", "scripts", `${name}.mjs`), link);
  chmodSync(join(root, "scripts", `${name}.mjs`), 0o755);
}
