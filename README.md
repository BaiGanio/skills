# BaiGanio skills

Agent skills you can install in any project. They work in Claude Code, Cursor, Codex, and other agents that read `SKILL.md` files.

| Skill | One line |
|---|---|
| [blast-radius](skills/blast-radius/SKILL.md) | Before you build a ticket, see what it touches. After you build it, see what you really changed. |

---

## blast-radius

You give it a ticket, an issue, an idea, or a PR. It tells you:

- **WHAT** the request wants, and how to check that it is done.
- **WHY** it is needed, and a simpler way, if there is one.
- **IMPACT**: which files, modules, and repos change, and how big the change is (S / M / L / XL).
- **FIT**: does the change follow your project's rules and architecture?
- **HEALTH**: code that already does the same job (reuse it), code smells, and bugs in the area.
- **SECURITY**: what changes for auth, input checks, secrets, and data.

It also draws 1 to 3 small diagrams, so you see where the change lands.

It reads code. It never changes code and never commits. It posts its report directly (use `--dry-run` to see it first).

### Install

Pick one.

**Any agent** (needs Node 22.20+):

```bash
npx skills add BaiGanio/skills --skill blast-radius        # for this project only
npx skills add BaiGanio/skills --skill blast-radius -g     # for all your projects
```

**Claude Code plugin:**

```
/plugin marketplace add BaiGanio/skills
/plugin install baiganio-skills@baiganio-skills
```

**By hand:** copy `skills/blast-radius/` into `.claude/skills/` (one project) or `~/.claude/skills/` (all projects).

Optional: `gh` (GitHub issues and PRs) and `az` (Azure DevOps). Without them, the skill writes a file instead of a comment.

### Update

Get the latest version of the skill.

**Any agent** (installed with `npx skills`):

```bash
npx skills update
```

**Claude Code plugin:**

```
/plugin marketplace update baiganio-skills
```

Then restart Claude Code.

**By hand:** copy `skills/blast-radius/` again, over the old folder.

### Use it

**Before you start the work:**

```
/blast-radius "Add dark mode to the settings page"      # an idea
/blast-radius #42                                        # a GitHub issue
/blast-radius https://github.com/org/repo/issues/42      # the same, as a URL
/blast-radius AB#1234                                    # an Azure DevOps work item
/blast-radius docs/plans/search.md                       # a plan or spec file
```

**When the work is done:**

```
/blast-radius done          # this branch compared with main
/blast-radius 57            # PR 57
```

In the "done" mode, it finds the first report, measures the real diff, and shows the guess next to the real result: which files you missed, what surprised you, and how close the guess was.

You can also just ask: *"what's the blast radius of issue 42?"* or *"my branch is ready for PR, check the impact"*.

### Where the report goes

| You started from | Before the work | After the work |
|---|---|---|
| A GitHub issue | a comment on the issue | a comment on the PR, plus a link on the issue |
| An Azure DevOps work item | a comment on the work item | a comment on the PR |
| An idea or a file | `docs/blast-radius/<id>.md` | an "After" section in the same file |

When you run it again, it edits the same comment or file. It does not post a second one. Old versions go into a closed "History" block.

### What a report looks like

The top part is short, so a reviewer can read it in 30 seconds:

```
## Blast radius: Add tags to notes
Size L · confidence medium · 6 files · 2 repos · security M · now 2 high, 5 medium

> WHAT: Notes get tags, and the web app can filter by one tag. Done when ...
> WHY: The list is flat. Users with many notes cannot find them.
> Other way: Filter in the browser. The API then only stores tags.
> Top findings: F1 bad JSON crashes the API · F2 API key in client code · ...
```

Then an impact diagram, the open questions, and closed blocks with the details.
Full example: [example-before-after.md](skills/blast-radius/examples/example-before-after.md).

### Flags

| Flag | What it does |
|---|---|
| `--dry-run` | Show the report in the chat only. Write nothing, post nothing. |
| `--before` / `--after` | Force the mode. |
| `--base <branch>` | Compare with this branch (default: the PR base, else `main`, else `master`). |
| `--out file` / `--out comment` | Force where the report goes. |
| `--id <id>` | Link this run to an older report. |
| `--run-checks` | Also run your tests, linters (check mode only), and dependency audits. |

### Your team's rules

The skill finds your rules in `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, ADRs (`docs/adr/`), lint config, and the patterns in your code.

To be strict, add `.blast-radius/standards.md`:

```markdown
## Must (a break is a high finding)
- All HTTP input is checked before use.

## Should (a break is a medium finding)
- New routes have a test.

## Security-sensitive paths
- src/auth/**
```

The full template is in [quality.md](skills/blast-radius/references/quality.md).

### Many repos

If your repo has an `AGENTS.md` or `CLAUDE.md` that lists other repos with local paths, the skill checks them too. It looks for shared contracts (API specs, shared config, auth settings) and for work that another repo has already done.

### Safety

- It never edits your code, never commits, and never pushes.
- It posts the comment (or writes the file) directly, with no draft in the chat. To see the report first, use `--dry-run`.
- It does not open `.env`, key files, or secret folders. If it finds a secret in code, it gives the file and line, never the value.
- It runs your tests or linters only with `--run-checks`.

---

## Develop and test

```bash
git clone https://github.com/BaiGanio/skills && cd skills
npx skills add ./ --list        # the CLI finds the skill
claude plugin validate .        # the plugin files are valid
```

Test scenarios and fake repos: [tests/README.md](tests/README.md). Open test tasks: [issues with the `testing` label](https://github.com/BaiGanio/skills/issues?q=label%3Atesting).

Found a wrong size, a missed file, or a step that confused the agent? Open an issue. Paste the chat summary and say what you expected.

## License

MIT
