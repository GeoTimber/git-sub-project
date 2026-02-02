# I Tried Git Submodules, Then Subtrees, Then Found a Git Feature Nobody Uses

*Share code between projects with full control, without the complexity*

---

Git submodules: everyone forgets `--recurse-submodules`, detached HEAD nightmares, remote dependencies that break your build.

Git subtrees: merged history spaghetti, painful to push changes back, impossible to tell what came from where.

I needed something simpler. I wanted to work on shared code directly in my projects without weird relative path imports in `deno.json` or messing with `npm link`. Then I found a Git feature almost nobody talks about.

## The Problem: Git Won't Let You Nest Repositories

Try adding a directory with a `.git` folder to your repo and Git yells at you:

```
warning: adding embedded git repository: my-shared-lib
hint: You've added another git repository inside your current repository.
hint: Clones of the outer repository will not contain the contents of
hint: the embedded repository and will not know how to obtain it.
```

**Git is telling you: you're not allowed to do this.** Clones won't get the nested repo's contents. You're supposed to use submodules instead.

But there's a workaround using a feature almost nobody talks about.

## The Pointer File Method

Here's the trick: `.git` doesn't have to be a directory. It can be a file pointing to one:

```
gitdir: .git-sub-project
```

Git reads this and treats `.git-sub-project/` as the repository. All normal git commands work. This is how Git worktrees work internally - it's native, not a hack.

Have you ever used worktrees? It's a way to check out multiple branches of the same repo in different directories simultaneously. Under the hood, each worktree uses a `.git` pointer file pointing back to the main repo's git directory. We're just repurposing that same mechanism.

**And now you can commit the nested repo to your parent repo.** The `.git` pointer file goes in `.gitignore`, while the `.git-sub-project/` directory is just a regular folder to Git - no warnings, no errors, full contents included.

Your teammates clone the project, they have your shared library too. No extra commands. No "did you remember to init the submodules?" Just code that works.

## How It Works

The setup creates this structure:
```
parent-project/
├── .git/                    # Parent repo
├── shared-lib/              # Nested sub-project
│   ├── .git                 # Pointer file (ignored)
│   ├── .git-sub-project/    # Full git directory (tracked!)
│   └── src/
```

The key: **the parent repo tracks the entire `.git-sub-project/` directory**. When teammates clone the parent repo, they get:

- All the code, ready to use
- Full git history of the nested repo
- No remote dependency
- **Zero setup required**

The code just works. No `--recurse-submodules`. No missing files. No extra commands.

## When You Want to Contribute Back

The linking step is **optional**. Only needed if you want to commit and push changes to the nested repo:

```bash
git link-sub-project --all
```

This creates the pointer files so git commands work in the nested directories. But if you're just using the code? Clone and go.

Want to edit the shared library? Go ahead. Make your changes, then when you're ready to share them back, create the link and commit them as a single clean commit in the sub-project. The remotes are already configured - just `git push`.

## The Commands

[git-sub-project](https://github.com/GeoTimber/git-sub-project) provides three commands. Installation is simple: any executable named `git-*` in your PATH becomes a git command. These are just bash scripts - clone the repo, run the install script, and you get native `git` commands:

**`git clone-sub-project`** - Add an existing repo as a nested sub-project:
```bash
git clone-sub-project git@github.com:team/shared-lib.git my-lib
```

**`git create-sub-project`** - Convert an existing directory:
```bash
git create-sub-project my-lib git@github.com:team/my-lib.git
```

**`git link-sub-project`** - Enable git commands in nested repos (optional, for contributors):
```bash
git link-sub-project --all
```

## Advantages

- Share libraries between your own and small team projects
- Extract common code from monolithic repos
- Maintain independent versions of shared components
- Sync back through PRs when you decide, with the commit message you choose, remotes already set up.
- Keep track of *why* you changed a shared library - it's right there in your parent repo's git history

## Trade-offs

- Parent repo stores nested repo's git data (uses disk space)
- Parent repo's commit history will include updates to the nested `.git-sub-project/` directory (if you made changes to the shared code). But hey - you have those changes tracked in your project, you can test them before making a PR, and you have a history explaining *why* you needed to change the shared library!
- Best for small teams, not enterprise scale

## IDE Support

Most IDEs recognize the `.git` pointer file automatically - syntax highlighting, git blame, git integration all just work. In VSCode, you can open just the sub-project folder and get full git tools: commits, branches, diffs, everything. It's a real repo, so it behaves like one.

## Why Not Package Managers?

For sharing a utility library between three internal projects, package managers add overhead:
- Publish cycles and version management
- Private registry setup
- Another tool in the stack

This approach: push to the library, pull in consuming projects. Full control, zero infrastructure.

---

MIT licensed: [github.com/GeoTimber/git-sub-project](https://github.com/GeoTimber/git-sub-project)

I built this because existing solutions didn't fit how my team works. Maybe it fits yours too.

I'd love to hear if others have solved this differently, or if you try it - let me know what works and what breaks!