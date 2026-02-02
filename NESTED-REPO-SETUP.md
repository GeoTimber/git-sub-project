# Nested Git Repository Setup Guide

## Overview

This directory uses a **Git pointer file method** to maintain an independent Git repository nested inside a parent repository. This guide explains how it works and how to use it.

## Use Case

Sharing code between multiple projects with:
- Full control over when to sync changes
- Clean separation - no messy merged histories
- Independent version control for each repository
- Zero setup for team members (commit everything approach)

## How It Works

This setup uses:
- A `.git` pointer file that references a custom git directory (e.g., `.git-sub-project/`)
- Both `.git` and the custom git directory are committed to the parent repository
- **Zero setup required** - clone parent repo and nested repo works immediately
- Perfect for small teams where disk space is not a concern

**Naming Convention**: By convention, the custom git directory is named `.git-sub-project` (appending `-sub-project` to `.git`). This makes it clear it's a nested repository and avoids conflicts with the parent's `.git` directory.

**Key Trade-off**: Parent repo tracks the custom git directory changes, but you simply don't commit those changes to the parent - only to the nested repo's own remote.

## Installation

Install the git sub-project commands as native Git commands:

```bash
# From the git-sub-project directory
cd git-sub-project

# Install globally (requires sudo)
sudo ./install.sh

# Or install to user directory (no sudo needed)
./install.sh ~/.local/bin
```

This installs three commands:
- `git clone-sub-project` - Clone existing repos as nested sub-projects
- `git create-sub-project` - Convert existing directories to nested sub-projects
- `git link-sub-project` - Link sub-projects after cloning parent repo (team member setup)

After installation, you can use them as **native Git commands** from anywhere!

## Quick Start (Recommended)

### Option 1: Clone an Existing Repository

Use `git clone-sub-project` to clone an existing repo as a nested sub-project:

```bash
# Clone with default branch
git clone-sub-project git@github.com:user/shared-lib.git my-library

# Clone specific branch
git clone-sub-project git@github.com:user/shared-lib.git my-library main
```

**What it does:**
1. Clones the repository into the specified subdirectory
2. Creates `.git-sub-project/` directory (following the naming convention)
3. Moves all `.git` contents to `.git-sub-project/`
4. Creates `.git` pointer file pointing to `.git-sub-project`
5. Verifies the setup works

**Then commit to parent repo:**
```bash
# Add to .gitignore with helpful comment
echo -e "\n# Nested repo git pointer (recreate locally: cd my-library && echo 'gitdir: .git-sub-project' > .git)\nmy-library/.git" >> .gitignore

# Add and commit everything
git add .gitignore my-library/
git commit -m "Add nested subproject: my-library"
```

**Note:** Git's built-in protections prevent tracking `.git` files. The .gitignore entry includes instructions for team members to recreate the pointer file.

### Option 2: Convert an Existing Directory

Use `git create-sub-project` to convert an existing directory into a nested sub-project:

```bash
# Without remote (add later)
git create-sub-project my-existing-lib

# With remote URL
git create-sub-project my-existing-lib git@github.com:user/my-lib.git
```

**What it does:**
1. Creates `.git-sub-project/` directory in the existing directory
2. Creates `.git` pointer file
3. Initializes git repository
4. Optionally adds remote URL
5. Stages all existing files (does NOT commit)

**Review and commit:**
```bash
cd my-existing-lib
git status              # Review what will be committed
git commit -m "Initial commit"
git push -u origin main # If you added a remote

# Then commit to parent repo
cd ..
# Add to .gitignore with helpful comment
echo -e "\n# Nested repo git pointer (recreate locally: cd my-existing-lib && echo 'gitdir: .git-sub-project' > .git)\nmy-existing-lib/.git" >> .gitignore

# Add and commit
git add .gitignore my-existing-lib/
git commit -m "Add nested subproject: my-existing-lib"
```

## Manual Implementation Steps

### Option A: Starting from Scratch

```bash
# In parent project directory, create the subdirectory
mkdir my-subproject
cd my-subproject

# Create .git-sub-project directory and initialize (following naming convention)
mkdir .git-sub-project
echo "gitdir: .git-sub-project" > .git
git init

# Set up remote for the nested repo
git remote add origin git@github.com:you/shared-lib.git

# Create initial content and commit
echo "# Shared Library" > README.md
git add .
git commit -m "Initial commit"
git push -u origin main
```

### Option B: Converting an Existing Cloned Repo

```bash
# Clone the existing shared repo
git clone git@github.com:you/shared-lib.git my-subproject
cd my-subproject

# Convert to pointer setup (using naming convention)
mkdir .git-sub-project
mv .git/* .git-sub-project/ 2>/dev/null
mv .git/.* .git-sub-project/ 2>/dev/null || true
rmdir .git
echo "gitdir: .git-sub-project" > .git

# Verify it works
git status  # Should work normally
```

### Commit Everything to Parent Repository

**Important** - Git prevents tracking `.git` files, so we add it to `.gitignore` with setup instructions:

```bash
# From parent repository root
cd ..

# Add .git pointer to .gitignore with instructions for team members
echo -e "\n# Nested repo git pointer (recreate locally: cd my-subproject && echo 'gitdir: .git-sub-project' > .git)\nmy-subproject/.git" >> .gitignore

# Add .gitignore and all subproject files
git add .gitignore my-subproject/

git commit -m "Add nested subproject with pointer setup"
git push
```

**Team member setup after cloning:**
```bash
# Link all sub-projects at once
git link-sub-project --all

# Or link a specific sub-project
git link-sub-project my-subproject
```

## Team Workflow

### For Collaborators (One-Time Setup)

When someone clones your parent repository, they need to link the sub-projects once:

```bash
# Clone the parent project
git clone git@github.com:you/parent-project.git
cd parent-project

# Link all sub-projects at once (recommended)
git link-sub-project --all

# Or link a specific sub-project
git link-sub-project my-subproject

# Now nested repos work!
cd my-subproject
git status  # Works now
git log     # See the full history
```

### Daily Workflow

```bash
# Work in the nested subproject
cd my-subproject
# ... edit files ...
git add .
git commit -m "Update feature X"

# Push to the subproject's own remote
git push origin main

# Parent repo will show .git-sub-project/ as modified - ignore this
cd ..
git status  # Shows my-subproject/.git-sub-project/ modified - don't commit this
```

### Syncing Across Multiple Projects

```bash
# In project-A, make changes to nested repo
cd project-a/my-subproject
# ... make changes ...
git commit -m "Changes"
git push origin main

# In project-B, pull the updates
cd project-b/my-subproject
git pull origin main

# Optionally update parent repo to track the new state
cd ..
git add my-subproject/.git-sub-project/
git commit -m "Update subproject to latest version"
```

## Alternative Methods

### Using GIT_DIR Environment Variable

```bash
cd my-subproject

# Initialize with custom git directory name
GIT_DIR=.git-sub-project git init

# For ongoing use, create an alias in your ~/.bashrc or ~/.zshrc
alias subgit='GIT_DIR=.git-sub-project git'

# Then use:
subgit status
subgit add .
subgit commit -m "message"
```

### Using --git-dir Command-Line Flag

```bash
cd my-subproject

# Initialize with custom git directory name
git --git-dir=.git-sub-project --work-tree=. init

# For every command
git --git-dir=.git-sub-project --work-tree=. status
git --git-dir=.git-sub-project --work-tree=. add file.txt
git --git-dir=.git-sub-project --work-tree=. commit -m "message"
```

## Important Considerations

1. **Naming Convention**: Always use `.git-sub-project` as the custom git directory name (appending `-sub-project` to `.git`). This convention:
   - Makes it clear the directory contains a nested repository
   - Avoids conflicts with the parent's `.git` directory
   - Provides consistency across projects
   - Works with the provided `git clone-sub-project` command

2. **Pointer File Path**: The path in `.git` file (`gitdir: .git-sub-project`) is relative to the `.git` file's location. You can also use absolute paths if needed.

3. **Remote Repository**: When you want to push this nested repo to a remote:
   ```bash
   cd my-subproject
   git remote add origin <url>
   git push -u origin main
   ```
   Works normally - the pointer is transparent to remote operations.

4. **IDE Support**: Most IDEs will recognize the `.git` pointer file and work correctly with the repository.

## Key Benefits

- ✅ **Minimal setup** - one command to create .git pointer after cloning
- ✅ **Complete history** - parent repo contains full git history of nested repo
- ✅ **Complete independence** - parent and subproject repos maintain separate histories
- ✅ **No remote dependency** - if nested repo remote is deleted, you still have full history
- ✅ **You control sync** - decide exactly when to sync changes between projects
- ✅ **Normal Git commands** - work as expected in nested repo
- ✅ **Version flexibility** - each project can be on different versions of the subproject
- ✅ **Perfect for small teams** - simple workflow, no complex submodule confusion

## Trade-offs

- ⚠️ Parent repo tracks `.git-sub-project/` (uses disk space - each commit in nested repo adds to parent repo size)
- ⚠️ Parent repo history includes snapshots of the nested repo's git data at each commit point

## Summary

The **git sub-project approach** provides the best balance for small teams:

- **Git pointer file method** creates independent repositories with `.git` pointing to `.git-sub-project/`
- **Naming convention** uses `.git-sub-project` suffix to clearly identify nested repositories
- **Automated setup** via `git-clone-sub-project` and `git-create-sub-project` commands
- **Track source + history** - `.git-sub-project/` and all source files are committed to parent repo
- **Ignore .git pointer** - added to `.gitignore` with instructions for team members
- **One command setup** for team members - create the pointer file after cloning
- **Clean separation** - each repo maintains independent history
- **Full control** - you decide when to sync changes between projects
- **Complete history** - parent repo contains full git history of nested repo

This avoids the complexity of submodules, the messy history of subtrees, and the remote dependency issues. The only cost is disk space (nested repo's git data is tracked) and a one-line setup command for team members.

## Tools

- **[git-clone-sub-project](git-clone-sub-project)** - Native Git command to clone existing repos as nested sub-projects
- **[git-create-sub-project](git-create-sub-project)** - Native Git command to convert existing directories to nested sub-projects
- **[git-link-sub-project](git-link-sub-project)** - Native Git command to link sub-projects after cloning parent repo
- **[install.sh](install.sh)** - Installation script to add all commands to your PATH as native Git commands
