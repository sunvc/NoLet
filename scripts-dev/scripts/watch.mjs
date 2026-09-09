#!/usr/bin/env node
// watch 模式打包：等价于 build --watch
process.argv.push("--watch");
await import("./build.mjs");
