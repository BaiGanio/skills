# Quality checks: FIT, HEALTH, SECURITY

## Where the project's standards come from

Read the ones that exist, in this order. When two sources disagree, the first one wins.

1. `.blast-radius/standards.md`: the team's own rules for this skill. See the template below.
2. `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, `.cursor/rules/`, `.cursorrules`: agent and team rules.
3. `CONTRIBUTING.md`, `docs/standards*`, `docs/conventions*`, `STYLEGUIDE*`.
4. ADRs (architecture decision records): `docs/adr/`, `docs/decisions/`, `adr/`, `docs/architecture*`.
5. Lint and format config: `.editorconfig`, `eslint.config.*`, `.eslintrc*`, `.prettierrc*`, `tsconfig.json` (strict flags), `pyproject.toml` (ruff, mypy), `.golangci.*`, `Directory.Build.props`, `*.ruleset`, `stylecop.json`, `.rubocop.yml`.
6. Patterns in the code itself: how the 2-3 nearest similar features are built (folders, naming, error handling, data access, DI, tests). Tag these rules **pattern**. A pattern is weaker than a written rule.

A written rule with "must", "never", or "always" is a **must** rule, wherever it is written. Other written rules are **should** rules.

Only list the rules that apply to this change. Max 8. Say which sources you found, and which you did not (for example "no ADRs, no lint config").

### `.blast-radius/standards.md` template

Give this to the user when they ask how to set rules:

```markdown
# Standards for blast-radius

## Must (a break is a high finding)
- All HTTP input is checked before use.
- No secrets in client code.

## Should (a break is a medium finding)
- New routes have a test.
- Use the existing `db` module. No direct SQL in routes.

## Architecture
- Layers: routes → services → db. No skipping.

## Security-sensitive paths (Security is at least M when these change)
- src/auth/**
- k8s/**

## Ignore (do not report)
- generated/**
```

## FIT: what to check

BEFORE has two status columns: **Now** (the current code) and **Plan** (the ticket's plan). AFTER has one: the diff. The header count uses Plan (BEFORE) or the diff (AFTER).

For each rule that applies:
- **follows**: the code or plan does what the rule says.
- **breaks**: it does not. This is also a finding (high for a must rule, medium for a should rule or an ADR, low for a pattern).
- **unclear**: you cannot tell yet (often in BEFORE). Say what decides it.

In AFTER, check only what the diff adds:
- A new line, or a new use of the broken way (a new call to a copy, a new raw compare), that breaks a rule: **breaks**, and a new finding.
- A line the diff did not touch, also in a changed function: not a FIT break. If it matters, it is a "Now:" finding.
- A changed line that keeps an old break as it was (the same call, only its arguments changed): not a FIT break. It is a "Now:" finding. Say in the Where cell that the line changed.
- A rule about tests ("every route has a test") breaks as **new** when the diff adds behavior with no test for it: a new route, a new parameter, or a new branch. This is true even when the old code had no tests. Old behavior with no test stays "Now:".
- The diff makes the same logic run two ways in one area (GET now uses `new URL()`, POST and DELETE still compare raw `req.url`): the "done two ways" smell is new, because the diff made it. Old lines that did not change still count as "Now:" for FIT.

Also check the architecture fit, even with no written rules:
- Does the change put code in the layer and folder where similar code lives?
- Does it add a second way to do something the project already does one way (a second HTTP client, a second config loader, a second date library)?
- Does it add a dependency between modules that did not depend on each other?

## HEALTH: what to check

Scope: the change list plus one level of callers. Not the whole repo.

**Duplication**
- BEFORE: search for code that already does part of the job: same names, same routes or queries, same constants, functions with a similar shape. Say "reuse `x` at `file:line`". Also search the other repos in the map (SKILL.md step 4.6).
- AFTER: code the diff copied from elsewhere, or that does the same as existing code. Name both places.

**Smells** (only report the ones that matter for this change)
- A function over ~50 lines, or nesting deeper than 3.
- A file that does many unrelated jobs.
- Magic values: numbers or strings that should be named or config.
- Dead code, commented-out code, unused exports, unused migrations or config. This smell is for old code ("Now:"). In AFTER, code the diff added that nothing uses is a **should-change** finding, not a smell (after.md step 3).
- Errors that are swallowed, or async code with no error path.
- Input used with no check.
- The same logic done two ways in the same area (for example one route parses the URL, the next compares the raw string).
- `TODO`, `FIXME`, or `HACK` in the touched files.

**Bugs**: real bugs you see while reading. Prove one with a read-only probe when you can (tag **run**).

## TEST TRUST (AFTER only)

Do the tests prove WHAT, or do they only pass? Check the tests and the code that the diff added or changed. Read the test bodies, not only their names.

**Done when vs tests.** Take each "Done when" check from WHAT. Find the test that proves it. Give each check one answer:
- **yes**: a test runs that check and asserts the result (the value, not only a count or "no error").
- **partly**: a test is near it but checks less (one layer only, a count only, the happy path only).
- **no**: no test, or the only test passes for the wrong reason.

When you can, prove the check with a read-only probe (tag **run**). A check that the code does not meet is a finding of its own kind (bug, security, or should-change), not a **test** finding.

**Drift**: tests that no longer match WHAT or the contract.
- An expected value that the diff changed so the test passes, while the new value goes against WHAT, the contract doc, or the BEFORE report.
- A test name that says X while its asserts check Y.
- A test that the diff deleted, skipped (`.skip`, `xit`, `@Ignore`, `@Disabled`, `pytest.mark.skip`, `t.Skip`), or commented out.

**Cheating**: code or tests that pass without doing the work.
- Code with a special path for test input: a hard-coded value that matches a test fixture, `NODE_ENV === 'test'`, or a check on a test name or a test-only header.
- Weaker asserts: an exact value changed to `toBeTruthy`, `>=`, or `assert.ok`, or a removed assert. A test with no real assert (it can never fail).
- A mock or stub of the code under test, so the test checks the mock.
- A try/catch or `.catch` in a test that hides a failure.
- Snapshots rewritten in full, with no reason in the diff.
- Test, coverage, or CI config that the diff changed to skip files or tests.

Each hit is a finding of kind **test**:
- **high**: cheating, or a deleted or skipped test that fails on the new code. Prove the fail with a probe when you can.
- **medium**: drift, a weaker assert, or a test with no real assert.
- **low**: a test name that does not match its asserts, when the asserts still prove something.

A cheat that hides a missing check is two findings, also when one fix closes both. The cheat is a **test** finding: the tests lie. The missing check has its own kind (bug, security, or should-change): the code is not safe. Example: `if (body.title === 'bad tags') return 400` is a high **test** finding, and the missing `tags` check is a **security** finding. Name the shared fix in both rows.

A missing test is not a **test** finding. It is a FIT or standard finding ("every route has a test"). Do not list it twice: in the Done-when table, name that finding.

## SECURITY: checklist

Walk this list for the touched area. Skip the items that do not apply. Each hit is a finding.

| Area | Look for |
|---|---|
| Authentication | Login, tokens, sessions, JWT validation (issuer, audience, expiry), API keys. |
| Authorization | Role or owner checks on new routes and data. A new route without the check the others have. |
| Input | Body, query, headers, files, and messages are checked for type, size, and format. Bad input must not crash the process. |
| Injection | SQL built from strings, shell commands with input, path joins with input, `innerHTML` or `dangerouslySetInnerHTML` with data, template injection. |
| Secrets | Keys, tokens, or passwords in code, config, client bundles, logs, or docs. Never print the value. |
| Data exposure | New fields in responses (personal data?), data in logs, error messages that show internals. |
| Transport and origins | CORS changes, cookies (`Secure`, `HttpOnly`, `SameSite`), HTTP vs HTTPS, redirect URIs. |
| Dependencies | New packages, scripts from CDNs, version pins. Who maintains it? With `--run-checks`, run the audit. |
| Infrastructure | Deploy files, k8s, CI secrets, permissions of workflows, public vs private repo. |
| Abuse | No limit on size or count (big bodies, many tags), no rate limit on a new public route. |

### Security size

Size what the change adds or removes. "Now:" holes in old code do not raise the size. They are findings. When an old hole makes a new risk worse (for example a new crash, and the key that guards it ships to every browser), size the new risk on its own, and name the old hole in the reason. When the old hole is the only thing that makes the new risk open to any visitor, the size is at most **L**. Say "Not XL: needs <old hole>".

| Size | Meaning |
|---|---|
| S | No security surface changes. |
| M | Touches input handling or adds data fields, and the checks are in place or easy to add. Or a new secret that lives only in env vars or a secret store. Or a path in "Security-sensitive paths" changes. |
| L | Changes authentication, authorization, CORS, or what user data goes out. Or a secret in code or config. Or a new third-party script. Or a new input path with no checks. |
| XL | A hole you can use now: an auth bypass, a secret in a public repo, an injection, or a crash any visitor can trigger with the new code alone (no old hole needed). |

## Findings

One table. Highest severity first. Inside one severity, new findings first, then "Now:" findings. Max 10 rows.

More than 10 findings:
- Fill the table with new findings first. "Now:" findings move below the table before new ones do. Inside the table, keep the order above.
- Every **new** finding gets an ID, also below the table. The merge score names it (scoring.md).
- A "Now:" finding below the table needs no ID. Only count it.
- Put the rest in one line under the table: `5 more: F11 (medium), F12 (medium), F13 (low); 2 "Now:" (low)`.

| ID | Sev | Kind | Where | What | Fix |
|---|---|---|---|---|---|
| F1 | high | security | `src/routes/notes.js:12` | Bad JSON in POST crashes the server (run) | Catch the parse error; return 400 |

- **Kind**: `security`, `bug`, `test`, `standard`, `architecture`, `duplication`, `smell`, `should-change`.
  - **security** or **bug**? A crash or a hole that someone from outside can trigger on purpose (bad input, a crafted request) is **security**. A wrong result that needs no bad intent is **bug**.
- **Sev**: **high** = a bug, a security hole, possible data loss, or a must rule broken. **medium** = will cost time soon, or a should rule broken. **low** = style, or a pattern not followed.
- **should-change** severity: **medium** by default. **high** only when a must rule names that exact file or contract. Example: `AGENTS.md` says "The API shape is in `docs/api.md`. Both repos must match it." The diff changes the API, not `docs/api.md`: high. Name the rule in What (`AGENTS.md:12`). Only the finding for the named file gets high. Other files the rule touches only through it (a client in another repo) stay medium. **low** when only a comment, or a list in a README, is out of date.
- One root cause is one finding. Give it the highest severity of its effects, and name the other effects in What (for example the must rule it breaks). Example: `tags` is not checked, so `tags: null` crashes the API and the must rule "all input is checked" breaks: one high finding, not a high and a medium. This joins effects of the **new** code only. An old gap stays its own "Now:" finding, even when the same fix closes both (old `title` and `text` with no checks). Name the shared fix in both rows.
- The one-root-cause rule is for one gap with many effects. A cheat and the gap it hides are two findings (TEST TRUST).
- A finding about code that exists today starts with "Now:". Suggest fixing a high one in a separate ticket first.
- A live secret anywhere a stranger can read it (a public repo, its git history, a client bundle) is **high**, even as "Now:". To search git history, redact the value: `git log -p -S '<name>' | sed -E 's/(key|token|secret|password)([^:=]*[:=]).*/\1\2 <redacted>/I'`.

## `--run-checks`

Only with this flag. Never use a fix or write flag.

| Kind | Examples (use what the project has) |
|---|---|
| Tests | `npm test`, `dotnet test`, `pytest`, `go test ./...` |
| Lint, check mode | `npx eslint <files>`, `npx prettier --check <files>`, `ruff check`, `dotnet format --verify-no-changes`, `golangci-lint run` |
| Audit | `npm audit --omit=dev`, `dotnet list package --vulnerable`, `pip-audit` |

Report each as pass, fail (with the first 5 problems), or not found. Tag results **run**.
