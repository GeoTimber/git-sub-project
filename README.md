# Git Sub-Project

A simple toolset for managing nested Git repositories using the pointer file method. Share code between projects with full control over synchronization, without the complexity of submodules or messy merged histories.

## What is This?

Git Sub-Project provides native Git commands to create and manage nested repositories inside parent repositories:

- **Clean separation** - Each repository maintains independent history
- **Zero setup** - Clone parent repo and nested repos work immediately
- **Full control** - You decide when to sync changes between projects
- **No complexity** - No submodule confusion, no merged histories

Perfect for small teams sharing code between multiple projects.

## Installation

```bash
# Clone this repository
git clone <this-repo-url>
cd git-sub-project

# Install globally (requires sudo)
sudo ./install.sh

# Or install to user directory (no sudo needed)
./install.sh ~/.local/bin
```

This installs three native Git commands:
- `git clone-sub-project` - Clone existing repos as nested sub-projects
- `git create-sub-project` - Convert existing directories to nested sub-projects
- `git link-sub-project` - Link sub-projects after cloning parent repo (team member setup)

## Quick Start

### Clone an Existing Repository

```bash
# Clone the repo as a nested sub-project
git clone-sub-project git@github.com:user/shared-lib.git my-library

# Add to parent repo's .gitignore and commit
echo -e "\n# Nested repo git pointer (recreate locally: cd my-library && echo 'gitdir: .git-sub-project' > .git)\nmy-library/.git" >> .gitignore
git add .gitignore my-library/
git commit -m 'Add nested subproject: my-library'
```

### Convert an Existing Directory

```bash
# Create nested sub-project
git create-sub-project my-existing-lib git@github.com:user/my-lib.git

# Commit the new nested repo
cd my-existing-lib
git commit -m "Initial commit"
git push -u origin main

# Add to parent repo
cd ..
echo -e "\n# Nested repo git pointer (recreate locally: cd my-existing-lib && echo 'gitdir: .git-sub-project' > .git)\nmy-existing-lib/.git" >> .gitignore
git add .gitignore my-existing-lib/
git commit -m 'Add nested subproject: my-existing-lib'
```

### Team Member Setup (One-Time)

After cloning the parent repo, link the sub-projects:

```bash
# Link all sub-projects at once
git link-sub-project --all

# Or link a specific sub-project
git link-sub-project my-library
```

Now git operations work in the nested repos!

## How It Works

Uses Git's pointer file feature (`.git` file pointing to custom directory):
- `.git` pointer file references `.git-sub-project/` directory
- Both are committed to the parent repository
- Team members get zero-setup experience (clone and go!)
- Each repo maintains completely independent history

**Naming Convention**: Custom git directory is named `.git-sub-project` (appending `-sub-project` to `.git`), making it clear it's a nested repository.

## Use Cases

- **Sharing libraries** between multiple projects
- **Extracting common code** from monolithic repos
- **Maintaining independent versions** of shared components
- **Syncing when ready** instead of automatic updates

## Documentation

📖 **[Full Documentation](NESTED-REPO-SETUP.md)** - Complete guide including:
- Detailed installation instructions
- Manual setup steps
- Team workflow examples
- Alternative methods
- Important considerations
- Troubleshooting

## Why Not Submodules or Subtrees?

**Git Submodules:**
- ❌ Complex workflow
- ❌ Easy to mess up
- ❌ Requires `--recurse-submodules` flags
- ❌ Only tracks commit SHA (not full history)
- ❌ Depends on remote availability
- ❌ Confusing for team members

**Git Subtrees:**
- ❌ Merges histories together
- ❌ Harder to extract changes back
- ❌ Can get messy over time

**Git Sub-Project:**
- ✅ Simple and transparent
- ✅ Independent histories
- ✅ One-command setup for team
- ✅ Full history in parent repo
- ✅ No remote dependency
- ✅ Full control over syncing

## Trade-offs

- Parent repo tracks nested repo's git data (uses disk space)
- Parent repo history includes snapshots of nested repo state
- Best for small teams where disk space isn't a concern

## Tools

- **[git-clone-sub-project](git-clone-sub-project)** - Clone repos as nested sub-projects
- **[git-create-sub-project](git-create-sub-project)** - Convert directories to nested sub-projects
- **[git-link-sub-project](git-link-sub-project)** - Link sub-projects after cloning parent repo
- **[install.sh](install.sh)** - Installation script
- **[NESTED-REPO-SETUP.md](NESTED-REPO-SETUP.md)** - Full documentation

## License

MIT License - completely free and open source. Use it however you want!

## Contributing

Contributions welcome! Feel free to:
- Report issues
- Submit pull requests
- Suggest improvements
- Share your use cases

---

Made with practicality in mind. Because sometimes the simplest solution is the best solution.
