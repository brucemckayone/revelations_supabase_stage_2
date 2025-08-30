#!/usr/bin/env node

/**
 * Script to update database.js imports to database.ts
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function updateImportsInFile(filePath) {
  try {
    const content = fs.readFileSync(filePath, "utf8");

    // Replace database.js imports with database.ts
    const updatedContent = content.replace(
      /from\s+["']([^"']*\/)?database\.js["']/g,
      'from "$1database.js"'
    );

    // If the content changed, write it back
    if (content !== updatedContent) {
      fs.writeFileSync(filePath, updatedContent, "utf8");
      console.log(`✅ Updated: ${filePath}`);
      return true;
    }

    return false;
  } catch (error) {
    console.error(`❌ Error updating ${filePath}:`, error.message);
    return false;
  }
}

function findFilesToUpdate(dir, extensions = [".js", ".ts", ".mjs"]) {
  const files = [];

  function searchDirectory(currentDir) {
    const items = fs.readdirSync(currentDir);

    for (const item of items) {
      const fullPath = path.join(currentDir, item);
      const stat = fs.statSync(fullPath);

      if (
        stat.isDirectory() &&
        !item.startsWith(".") &&
        item !== "node_modules"
      ) {
        searchDirectory(fullPath);
      } else if (
        stat.isFile() &&
        extensions.some((ext) => item.endsWith(ext))
      ) {
        files.push(fullPath);
      }
    }
  }

  searchDirectory(dir);
  return files;
}

console.log(
  "🔄 Updating database.js imports to database.js (keeping .js extension for compatibility)...\n"
);

const rootDir = __dirname;
const filesToCheck = findFilesToUpdate(rootDir);

let updatedCount = 0;

for (const file of filesToCheck) {
  if (updateImportsInFile(file)) {
    updatedCount++;
  }
}

console.log(`\n✨ Import update complete!`);
console.log(`📁 Checked ${filesToCheck.length} files`);
console.log(`✅ Updated ${updatedCount} files`);

if (updatedCount === 0) {
  console.log("ℹ️  All files were already using the correct import paths");
}


