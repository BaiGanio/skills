# Tests for blast-radius

The tests run the skill on two small fake repos. A helper agent follows `SKILL.md` like a real user would, then reports what it printed, what it wrote, and which steps were unclear.

## Make the fake repos

```bash
tests/fixtures/make-fixtures.sh /tmp/br-test          # notes-api + notes-web, both on main
tests/fixtures/make-tags-branch.sh /tmp/br-test       # adds branch feat/tags to notes-api (API only, web not done)
tests/fixtures/make-cheat-branch.sh /tmp/br-test      # adds branch feat/tags-cheat (tests that pass without proving the work); run after T1
```

`notes-api` has an `AGENTS.md` that maps `../notes-web`, a contract in `docs/api.md`, and team rules in `.blast-radius/standards.md`.
It also has known problems on purpose: a typo in the 404 text, a second copy of the body parser (`src/routes/notes.js` vs `src/http.js`), no input checks, and an API key in `notes-web/src/config.js`.

## Scenarios

| ID | Setup | Command (in notes-api) | Pass when |
|---|---|---|---|
| T1 | fixtures | `/blast-radius "Add tags to notes. Users can add tags to a note and filter the list by tag in the web app."` | Writes only `docs/blast-radius/idea-add-tags-notes.md`. Size L. 2 repos. Cross-repo diagram. FIT lists rules from `standards.md`. Finds the duplicate body parser (reuse `src/http.js`). Security M or L. No code changed. |
| T2 | fixtures | `/blast-radius "Fix the typo in the 404 error message" --dry-run` | Size S. One-line impact form. No file written. |
| T3 | T1 report + tags branch | `/blast-radius done` on `feat/tags` | Adds an "After" section to the T1 file. Missed: the notes-web files. Surprise or should-change: the unused migration, `docs/api.md`. FIT: input-check rule broken. Accuracy given. Look ahead: 1-5 items (or "none seen"), none repeats a finding. Merge score: the math line matches the rule in scoring.md; "not ready" (a new high finding). The `docs/api.md` finding is high (must rule in `AGENTS.md:12`). "Tests" block: 0 of 4 proved; drift and cheating "none seen". |
| T4 | tags branch, no report | `/blast-radius done` | Asks for a BEFORE report once. Writes `docs/blast-radius/branch-feat-tags.md`. AFTER-only shape. Finds the `tags: null` crash. |
| T5 | T1 report | T1 again with "...and edit tags later" | Same file. `version=2`. Old text in History. |
| T6 | fixtures | `/blast-radius notes` (user does not answer) | Asks "What should change about notes?" with choices. Writes nothing. Prints the "stopped" summary. |
| T7 | a GitHub sandbox repo with an issue | `/blast-radius #1`, then `done` with a PR | Posts directly, with no draft in the chat and no question. Re-run edits the same comment. AFTER posts on the PR and a link on the issue. |
| T8 | a real repo | `/blast-radius <plan file> --dry-run` | No file written. Useful findings. |
| T9 | T1 report + cheat branch | `/blast-radius done` on `feat/tags-cheat` | "Tests: do they prove WHAT?" block: "Bad tags get 400" is **no** (the test passes only through the special path). **test** findings: the special path for `title: "bad tags"` (high, cheating); the skipped `tag match is exact`, which fails on the new code (high); the weaker assert in `add and list` and the assert that can never fail in `filter by tag` (medium). A probe shows that `tags: 5` with another title gets 201. Merge score "not ready". |

After each run, check `git status --short` in both repos: only the report file may be new.

## Install checks

```bash
npx skills add ./ --list
claude plugin validate .
```
