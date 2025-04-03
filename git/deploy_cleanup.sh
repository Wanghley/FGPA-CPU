#!/bin/bash
# Exit immediately on error and treat unset variables as an error
set -euo pipefail

# Ensure we are on the deploy branch
if ! git rev-parse --verify deploy >/dev/null 2>&1; then
  echo "Error: Deploy branch does not exist."
  exit 1
fi

git checkout deploy
echo "Moving required files..."

# Create a temporary directory to store required files
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"; echo "Temporary files cleaned up due to an error.";' EXIT

# Move only folders and .v files from main/proc/ to the temporary directory
mkdir -p "$tmp_dir/proc"
if [ -d "main/proc" ]; then
  # Copy directories
  find "main/proc" -type d -exec mkdir -p "$tmp_dir/{}" \;
  # Copy only .v files
  find "main/proc" -name "*.v" -exec cp {} "$tmp_dir/{}" \;
else
  echo "Warning: main/proc/ is empty or does not exist. Skipping..."
fi

# Move main/constraints.xdc to the temporary directory
if [ -f "main/constraints.xdc" ]; then
  cp "main/constraints.xdc" "$tmp_dir/"
else
  echo "Warning: main/constraints.xdc not found. Skipping..."
fi

# Important: Create a list of files to keep - this will help us avoid deleting .git
mkdir -p "$tmp_dir/to_keep"
cp -r .git "$tmp_dir/to_keep/"

# Instead of dangerous find/delete, use git to get a list of tracked files and remove them selectively
git ls-files | xargs rm -f 2>/dev/null || true
# Remove directories that might still exist (but keep .git)
find . -mindepth 1 -maxdepth 1 -type d -not -name ".git" -exec rm -rf {} \; 2>/dev/null || true

# Restore the .git directory from our backup (just in case)
cp -r "$tmp_dir/to_keep/.git" . 2>/dev/null || true

# Restore the required files to root
if [ -d "$tmp_dir/proc" ] && [ "$(ls -A "$tmp_dir/proc" 2>/dev/null)" ]; then
  cp -r "$tmp_dir/proc/"* ./ 2>/dev/null || true
fi

if [ -f "$tmp_dir/constraints.xdc" ]; then
  cp "$tmp_dir/constraints.xdc" ./
fi

# Cleanup temporary directory
rm -rf "$tmp_dir"
echo "Files moved and cleanup completed."

# Verify git is still working
if ! git status >/dev/null 2>&1; then
  echo "ERROR: Git repository was damaged. Please check your .git directory."
  exit 1
fi

git add .
if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "Deploy branch cleanup and file move"
  git push origin deploy
fi

echo "Deployment cleanup done!"