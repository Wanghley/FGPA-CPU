#!/bin/bash
set -euo pipefail
echo "🚀 Starting reorganization on main branch"

# Make sure we are on main
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" != "main" ]]; then
  echo "❌ Error: This script must be run from the 'main' branch. You are on '$current_branch'."
  exit 1
fi

# Create temporary directory for staging
tmp_dir=$(mktemp -d)
# Don't clean up on EXIT - we'll do it manually at the end
trap 'echo "🧹 Error occurred. Temporary files at $tmp_dir"' ERR

# Ensure the temp directory exists
echo "📦 Preparing temporary directory for staging files..."
mkdir -p "$tmp_dir"
echo "📦 Backing up required files for reorganization..."

# ---------- Copy Verilog files from main/proc/ to src/ ----------
if [ -d "main/proc" ]; then
  echo "📁 Copying Verilog files from main/proc to src/..."
  find "main/proc" -name "*.v" | while read file; do
    rel_path=${file#main/proc/}
    mkdir -p "$tmp_dir/src/$(dirname "$rel_path")"
    cp "$file" "$tmp_dir/src/$rel_path"
  done
else
  echo "⚠️ Warning: main/proc/ not found or empty."
fi

# ---------- Copy submodules/ as-is ----------
if [ -d "submodules" ]; then
  echo "📁 Copying submodules/..."
  rsync -av --exclude='.git' submodules/ "$tmp_dir/submodules/"
fi

# ---------- Copy validation/ as-is ----------
if [ -d "validation" ]; then
  echo "📁 Copying validation/..."
  rsync -av --exclude='.git' validation/ "$tmp_dir/validation/"
fi

# ---------- Copy constraints.xdc to root ----------
if [ -f "main/constraints.xdc" ]; then
  echo "📄 Copying main/constraints.xdc to root..."
  cp main/constraints.xdc "$tmp_dir/constraints.xdc"
else
  echo "⚠️ Warning: constraints.xdc not found."
fi

# ---------- Copy README.md to root ----------
if [ -f "README.md" ]; then
  echo "📄 Copying README.md to root..."
  cp README.md "$tmp_dir/README.md"
else
  echo "⚠️ Warning: README.md not found."
fi

# ---------- Copy .gitignore and .gitmodules to root ----------
if [ -f ".gitignore" ]; then
  echo "📄 Copying .gitignore to root..."
  cp .gitignore "$tmp_dir/.gitignore"
else
  echo "⚠️ Warning: .gitignore not found."
fi

if [ -f ".gitmodules" ]; then
  echo "📄 Copying .gitmodules to root..."
  cp .gitmodules "$tmp_dir/.gitmodules"
else
  echo "⚠️ Warning: .gitmodules not found."
fi

# ---------- Rename test_files to tests ----------
if [ -d "test_files" ]; then
  echo "📁 Renaming test_files/ to tests/..."
  rsync -av --exclude='.git' test_files/ "$tmp_dir/tests/"
else
  echo "⚠️ Warning: test_files/ not found."
fi

# ---------- Backup .git directory ----------
echo "🔒 Backing up .git directory..."
rsync -av .git/ "$tmp_dir/.git/"

# ---------- List all files in temp directory before cleaning ----------
echo "📋 Contents of temporary directory:"
ls -la "$tmp_dir"

# ---------- Clean main branch but preserve .git ----------
echo "🧹 Cleaning main branch (preserving .git)..."
find . -mindepth 1 -maxdepth 1 -not -path "./.git" -exec rm -rf {} \;

# ---------- Restore all staged content ----------
echo "♻️ Restoring reorganized content to main branch..."
rsync -av "$tmp_dir/" ./

# ---------- List all files after restoring ----------
echo "📋 Contents after restoration:"
ls -la

# ---------- Commit changes ----------
echo "✅ Staging and committing reorganization..."
git add .
if git diff --cached --quiet; then
  echo "📭 No changes to commit."
else
  git commit -m "Reorganize repository structure"
  echo "📤 You can push changes with: git push origin main"
fi

# ---------- Clean up the temporary directory ----------
rm -rf "$tmp_dir"
echo "🧹 Temporary files cleaned up."
echo "🎉 Repository reorganization completed successfully!"