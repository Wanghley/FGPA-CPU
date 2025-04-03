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

# Explicitly create the temporary proc directory to store Verilog files
mkdir -p "$tmp_dir/proc"

# Copy Verilog files and directory structure from main/proc to temporary directory
if [ -d "main/proc" ]; then
  echo "Copying Verilog files from main/proc..."
  
  # First copy the directory structure
  find "main/proc" -type d | while read dir; do
    relative_dir=${dir#main/}
    mkdir -p "$tmp_dir/$relative_dir"
  done
  
  # Then copy the .v files
  find "main/proc" -name "*.v" | while read file; do
    relative_file=${file#main/}
    cp "$file" "$tmp_dir/$relative_file"
    echo "Copied: $file"
  done
else
  echo "Warning: main/proc/ is empty or does not exist. Skipping..."
fi

# Move main/constraints.xdc to the temporary directory
if [ -f "main/constraints.xdc" ]; then
  cp "main/constraints.xdc" "$tmp_dir/"
  echo "Copied: main/constraints.xdc"
else
  echo "Warning: main/constraints.xdc not found. Skipping..."
fi

# Backup the git directory
echo "Backing up .git directory..."
cp -r .git "$tmp_dir/git_backup"

# Clean up the current directory but preserve .git
echo "Cleaning up current directory (preserving .git)..."
find . -mindepth 1 -maxdepth 1 -not -path "./.git" -not -path "./.git*" -exec rm -rf {} \; 2>/dev/null || true

# Check if git is still intact
if ! git status >/dev/null 2>&1; then
  echo "Git repository was damaged. Restoring from backup..."
  rm -rf .git
  cp -r "$tmp_dir/git_backup" .git
fi

# Copy the contents from proc in tmp_dir to root
echo "Restoring Verilog files to root directory..."
if [ -d "$tmp_dir/proc" ] && [ "$(ls -A "$tmp_dir/proc" 2>/dev/null)" ]; then
  cp -r "$tmp_dir/proc/"* ./ 2>/dev/null || echo "Note: No files to copy from proc directory."
  # List what was copied
  echo "Files copied to root:"
  ls -la | grep -v "^d"
  echo "Directories copied to root:"
  ls -la | grep "^d" | grep -v "\.git"
fi

if [ -f "$tmp_dir/constraints.xdc" ]; then
  cp "$tmp_dir/constraints.xdc" ./
  echo "Constraint file copied to root."
fi

# Cleanup temporary directory
rm -rf "$tmp_dir"
echo "Files moved and cleanup completed."

# Verify git is still working
if ! git status >/dev/null 2>&1; then
  echo "ERROR: Git repository was damaged. Please check your .git directory."
  exit 1
fi

# Add and commit changes
echo "Committing changes..."
git add .
if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "Deploy branch cleanup and file move"
  git push origin deploy
fi

echo "Deployment cleanup done!"