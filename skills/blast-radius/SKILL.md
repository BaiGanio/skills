---
name: blast-radius
description: Measure what a ticket, issue, idea, or PR changes in the code, and how well it fits. BEFORE the work - WHAT, WHY, an impact guess, code to reuse, and rules to follow. AFTER the work - the real diff vs the guess, plus duplication, smells, broken standards, security, test trust (do the tests prove WHAT, with no drift or cheating), a look ahead at what the change can cause later (other code, code flow, design), and a merge score. Use for "/blast-radius", "blast radius", "impact of this ticket", "how big is this change", "what does this touch", or when a branch or PR is ready for review.
license: MIT
metadata:
  version: 0.7.0
  repo: https://github.com/BaiGanio/skills
---

# Blast radius

Understand a change before and after it is made:

1. **WHAT** does the request try to achieve?
2. **WHY** is it needed, and why this way?
3. **IMPACT**: what does it touch, and how big is it?
4. **FIT**: does it follow the project's architecture and standards?
5. **HEALTH**: duplication, code smells, and bugs in the touched area.
6. **SECURITY**: what changes for auth, input, secrets, and data?
7. **AHEAD** (AFTER only): what can the change cause later, in other code, the code flow, and the design?
8. **TEST TRUST** (AFTER only): do the tests prove WHAT, or do they only pass?

Two modes:

- **BEFORE**: the work has not started. Guess the impact. Find code to reuse, smells to know about, and the rules the work must follow.
- **AFTER**: the work is done. Measure the real diff, compare it with the BEFORE guess, check the diff for FIT, HEALTH, and SECURITY, check that the tests prove WHAT (no drift, no cheating), look ahead for risks that are not bugs yet, and give a merge score (0-100) from a fixed rule.

## Rules

- Do not change code. The only thing this skill writes is its report (a file or a comment).
- Never commit. Never push. The user commits the report file with their work.
- Post the comment or write the file directly. Do not print the report in the chat, and do not ask first. To see the report before it goes out, the user runs `--dry-run`.
- Do not open `.env*`, `*.pem`, `*.key`, `*.pfx`, `secrets.*`, or files in a `secrets/` folder. Other files you may read, even if they hold a secret. If you find one, give the file and line. Never print or type the value.
- Read-only probes are allowed: a short command that writes no file, opens no port, and uses no network. It may import project modules and call them in-process (for example `node -e` that calls a function, or `server.emit('request', req, res)` with fake objects). Set any needed secret env var to a throwaway value. A probe may set env vars and process globals (for example `process.argv`) only inside its own process. Name the patch once, on a "Probes:" line under the findings table (for example "Probes: set `process.argv[1]` to import `src/server.js`"), so the reader knows the code did not run exactly as shipped. The claims keep the plain **run** tag. Probes prove a claim. Linters, scanners, and test suites run only with `--run-checks`.
- Tag each claim: **seen** (you read it in the code or diff), **run** (a probe or check proved it), or **guess** (no proof). Bugs you find by reading are **seen**. Rules you infer from the code are tagged **pattern**.
- Put each finding in one place only. Other sections point to it ("see H2").
- Keep the top of the report short. A reviewer must read it in 30 seconds. Details go into closed `<details>` blocks.
- Keep diagrams small: max 10 boxes each, max 4 words per label.

## Arguments

```
/blast-radius <input> [--before | --after] [--dry-run] [--base <branch>] [--out file|comment] [--id <id>] [--run-checks]
```

| Flag | Meaning |
|---|---|
| `--before`, `--after` | Force the mode. Without them, pick the mode with step 1. |
| `--dry-run` | Show the report in the chat only. Write no file. Post no comment. |
| `--base <branch>` | The branch to compare with in AFTER mode. Default: the PR base, else `main`, else `master`. |
| `--out file\|comment` | Force where the report goes. |
| `--id <id>` | Use this ticket ID. Use it to link a re-run or an AFTER run to an older report. |
| `--run-checks` | Run the project's tests, linters (check mode only), and dependency audits. See quality.md. |

## 1. Pick the mode

First find the **code repo**. Usually it is the current repo. If the input is a plan or spec about another repo (for example a brief in a home repo), find that repo now (step 4.5 tells how), and use its git state below.

Then look at the git state of the code repo: `git branch --show-current`, `git status --short`, commits not in the base, and `gh pr view --json number,url` when the remote is GitHub. Ignore `docs/blast-radius/` in this check: it holds reports, not code.

Check these rows **in order**. Use the first row that fits.

| # | Input | Mode |
|---|---|---|
| 1 | No verb and no named change: a single word or a bare noun (`notes`, `auth flow`) | Vague. See below. |
| 2 | A PR number or PR URL | AFTER |
| 3 | `done`, `ready`, `ready for PR`, or no input, and the branch has commits not in the base | AFTER. With no PR, the header says `branch <name> (no PR)`. |
| 4 | `done` or no input, HEAD is the base branch, and nothing is changed | Say "nothing to measure" and stop. |
| 5 | An issue for which a PR or a branch with commits already exists | Ask: "BEFORE again, or AFTER on <PR/branch>?" |
| 6 | A BEFORE input, but the code for it is already partly changed (commits or uncommitted files) | Ask: "BEFORE on what is left, or AFTER-only on what is done?" Warn when the changes sit uncommitted on the default branch. For "what is left": size only the work left, and put the done parts on an **Already done** line in the top box. |
| 7 | Free text, a file path (plan, spec), an issue URL or number, a work item ID | BEFORE |
| 8 | Nothing fits | Ask the user. Do not guess. |

### Vague input

1. Do a quick scan first (steps 3.1 and 3.2; in a repo of under ~20 files, read it all), so the question can offer real choices.
2. Ask: "What should change about <word>?" Offer 2-4 short choices from the scan.
3. When the user picks a choice, run BEFORE with that choice as the text.
4. No answer: stop. Write nothing. Print the "stopped" summary.

A ticket that names a change but is thin (for example "make login better") is not vague. Go on with confidence **low** and list open questions.

## 2. Read the input

Read [references/sources.md](references/sources.md) for the commands for each source: GitHub issue, GitHub PR, Azure DevOps work item, Azure Repos PR, text, or a file.

From the input, get:
- **Title**, **body**, the comments that add scope, and the **acceptance criteria**.
- **Ticket ID** (`--id` overrides all of these):
  - GitHub issue: the number, for example `42`. Azure DevOps: `AB1234`.
  - Text: `idea-` plus the first 4 **different** words of the **first sentence** that are not stop words (a, an, the, to, of, in, on, for, and, or, with, by, is, be, can, should, users, user), lowercase, joined by `-`. Example: "Add tags to notes. Users can..." → `idea-add-tags-notes`. Fewer than 4 left: use what is left.
  - File: the file name without extension, for example `brief-cosmic-origins`.
  - AFTER-only with no ticket: `branch-` plus the branch name with `/` changed to `-`, for example `branch-feat-tags`.
  - Always print the ID in the chat summary, so the user can pass it with `--id` later.

If the ticket names files, routes, or steps, check that each one still exists. List the ones that are gone as open questions.

If the input lives in one repo but the code is in another, measure the code repo (found in step 1). Say so in the report.

**Re-run with new text** (same ID, but the ticket changed): make a new version, and add a line **Scope change since v<n>** to the top box.

## 3. WHAT and WHY

Write these before you map the code. Fix them after, if the code shows something new.

- **WHAT**: the goal in one sentence. Then: what is true after the change, and how to check it (a command, a test, or a click path). Use the acceptance criteria when the ticket has them.
- **WHY**: the problem now, who feels it, and the value of the fix. If the ticket does not say why, guess it from the ticket and the code, tag it **guess**, and add an open question.
- **Other way**: a different approach than the ticket asks for, simpler or safer, if you see one (for example "reuse X", "a config flag instead of new code"). Else "none seen". Choices the ticket leaves open are not "Other way". They go in open questions, and you size the simplest one (scoring.md).

## 4. Map the code

Find, in this order. Stop when you have enough for steps 5-7.

1. Languages, build files, entry points, top-level folders. One quick look, not a full read.
2. The code that the ticket names. Search for its nouns and verbs: routes, classes, components, tables, config keys, UI text.
3. One level out: the callers of that code, and the code it calls. Use imports, route tables, DI registration, and config.
   AFTER with a BEFORE report: start from the BEFORE file list and the diff. Map only those and one level out. Do not map the repo again.
4. Tests for that code. CI files. Deploy files (Docker, k8s, Terraform, workflow files). Check deploy facts against what the code and its comments say (which store, which env vars, which port). A mismatch is a finding.
5. **Other repos.** Look for a map file in the repo root: `AGENTS.md`, `CLAUDE.md`, or `README.md` with a list of other repos and their local paths. Paths there are relative to that repo's root. Other repos are read only. Also look for contract files: shared fact files (for example `PLATFORM.md`), OpenAPI specs, `.proto` files, JSON schemas, shared config. If the ticket touches a contract, check the other repos that use it (only the ones on disk). In a big repo, search only for the contract names (routes, fields, config keys, client IDs). A repo of under ~20 files: read it. No map file: check this repo only and say so.
6. **Already built elsewhere?** Search the other repos in the map for the feature itself (its main nouns), not only for contract names. Work that another repo already did is a **duplication** finding, and often the best "Other way".
7. **Depends on.** Work in a repo **outside** the change list that must happen first (for example a client or role that does not exist yet). Order of work inside the change list goes in Rollback, not here.

If the repo is big (more than about 2000 files) and your agent can start subagents, give each subagent one area to search. Merge their file lists.

Sort each file into one group. For files in another repo, start the path with the repo folder name (`notes-web/src/app.js`).
- **change**: an existing file that must change.
- **new**: a file to add.
- **delete**: a file to remove.
- **maybe**: could change, depending on a choice. Say which choice.

Tests: when a test file for the code exists, put it under **change**. Else under **new**.

## 5. IMPACT: measure

Read [references/scoring.md](references/scoring.md). Size these 8 parts:

| Part | What to write |
|---|---|
| Files | Count per group (change / new / delete / maybe), number of repos. |
| Design | What changes inside modules: types, functions, components, patterns. |
| Architecture | What changes between modules: layers, dependencies, data flow, services, stores. |
| Contracts | Shared facts that change: APIs, schemas, URLs, auth, config that other code or repos read. |
| Risk | What can break, and where: data, deploy, production, users. |
| Security | The size from the SECURITY check in step 6. |
| Tests | Tests to change, tests to add, and the gaps. |
| Rollback | How to undo it, the order of undo, and what makes undo hard. |

One tag per Notes cell, for example `(seen)`. When one sentence differs, tag that sentence only.

Then give:
- **Overall size**: the rule is in scoring.md.
- **Confidence**: high, medium, or low, with one reason.
- **Open questions**: things the ticket must answer before work starts. Max 5.

## 6. FIT, HEALTH, SECURITY

Read [references/quality.md](references/quality.md). It says where to find the project's standards, and what to check.

- **FIT**: list the project rules that apply to this change. For each: **follows**, **breaks**, or **unclear**, with the file and line.
  - BEFORE: the rules the work must follow (a short checklist for the person who does the work). Two columns: **Now** (does the current code in the touched area follow it?) and **Plan** (does the ticket's plan follow it: follows, breaks, or unclear).
  - AFTER: check the diff against each rule.
- **HEALTH**: only the touched area (the change list plus one level of callers).
  - BEFORE: code that already does part of this (reuse it), and smells or bugs in the area that will make the work harder.
  - AFTER: duplication, smells, and bugs that the diff adds. Also say which old smells the diff fixed.
- **SECURITY**: walk the checklist in quality.md for the touched area. Give the Security size and its findings.

Each finding gets an ID (F1, F2, ...), a severity (high, medium, low), a kind, a place (`file:line`), and a fix in one line. Max 10 findings, highest first. Count the rest.

Two kinds of finding:
- **New**: the change adds it (AFTER), or the plan would add it (BEFORE).
- **Now**: it exists already in the touched area. Start the text with "Now:". It does not raise the Security size or the overall size. If it is high, suggest a separate ticket first.

The header counts both, apart. BEFORE puts "now" first (`now 2 high, 4 low · new 0`), because a plan rarely adds findings yet. AFTER puts the diff's findings first (`findings 1 high · now 2 high`). The counts include the rows that did not fit in the table.

## 7. Draw

Read [references/diagrams.md](references/diagrams.md). Draw:
1. **Impact map**: always. For an S change with 1 or 2 boxes, write the one-line form instead.
2. **Before → after**: when Design or Architecture is M or bigger.
3. **Cross-repo flow**: when more than 1 repo is hit, or when the change depends on another repo (step 4.7). In AFTER, a repo is hit only when the diff changed it. A repo with only should-change work is not hit: show it in the impact map with the `todo` class.

Use Mermaid in files and GitHub comments. Use ASCII in Azure DevOps comments and in the chat summary.

## 8. Write the report

Read [references/report.md](references/report.md) for the template and the hidden markers.

### Where the report goes

| Source | BEFORE goes to | AFTER goes to |
|---|---|---|
| GitHub issue | A comment on the issue | A comment on the PR, plus a 1-line link comment on the issue |
| Azure DevOps work item | A comment on the work item | A comment on the PR (GitHub or Azure Repos) |
| Text or file | `docs/blast-radius/<ticket-id>.md` in the code repo | A new "After" section in the same file |

- An issue or work item in file mode (`--out file`, or the CLI is missing): `docs/blast-radius/<ticket-id>.md` too.
- AFTER-only with no BEFORE file: a new `docs/blast-radius/<ticket-id>.md`.
- The "code repo" is the repo with the most files in the change list. If that is not the current repo, say so and ask before you write there.
- `--out` overrides this table. If `gh` or `az` is missing or not logged in, write the file instead, and tell the user why.

### Order

1. If an older report of the **same mode** exists (a comment with the marker, or the file), do not add a second one. Move the old text into the "History" block (see report.md), then put the new text on top. Edit the comment in place. This is for a re-run: BEFORE again, or AFTER again. An AFTER run on a BEFORE report does not use History: it adds the "After" section under the BEFORE text and keeps the BEFORE text (after.md step 7).
2. With `--dry-run`: print the full report, then the chat summary, and stop.
3. Else write or post. Do not print the report in the chat.
4. Print the chat summary once, as the last thing.

## AFTER mode

In AFTER mode, read [references/after.md](references/after.md). It says how to get the diff, find the BEFORE report, measure, and compare.

## The chat summary

Print it once, as the last thing. Max 14 lines, max 80 characters each. Use a repo-relative path. The impact map wins the diagram space. Leave out the lines in [brackets] when they do not apply.

```
blast-radius <BEFORE|AFTER> · id <ticket-id> · size <S|M|L|XL> · confidence <high|medium|low>
WHAT: <one line>
[Repo: <code repo>, when it is not the current repo]
[Warn: <one line, for example "work uncommitted on master; a push deploys">]
<ASCII impact map, max 5 lines>
Files: <n> change, <n> new, <n> delete, <n> maybe · repos: <n> · security <S|M|L|XL>
Findings: <n> high, <n> medium, <n> low · now: <n> high · top: <F1, short>
[AFTER: score <n> <call> · guess <size>→<size> · accuracy <n>% · FIT <n>/<n> · ahead <n>]
[Tests: <n>/<n> done-when proved · <the worst test problem, short>]
Questions: <n, or "none">
Report: <path or URL, or "not written (dry run)">
```

In AFTER, leave out "<n> maybe" on the Files line: the diff has no maybe files.

The ASCII impact map has max 5 lines, and connector lines (`|`, `+-->`) count toward the 5. The whole summary stays max 14 lines.

The `Questions` line counts open questions. In AFTER with a BEFORE report, it counts the BEFORE questions that are still open ("Guess vs real" lists them). In AFTER-only, it counts the report's own open questions.

When you stop before a report (vague input, nothing to measure, the user said no):

```
blast-radius stopped · <reason in 5 words>
<the question you asked, with its choices, or what is missing>
Noticed: <up to 2 findings from the scan, or leave out>
Report: not written
```
