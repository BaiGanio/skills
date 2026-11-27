# AFTER mode

Read this file only in AFTER mode. It replaces nothing in SKILL.md: the steps there still apply.

1. **Get the diff.**
   - PR: see sources.md.
   - Branch: `git diff --stat <base>...HEAD` and `git diff <base>...HEAD`. Also list uncommitted changes (`git status --short`) apart. Say if the work is not committed yet.
2. **Find the BEFORE report.** Stop at the first hit.
   1. `--id`.
   2. The PR's linked issues (`closingIssuesReferences`, `AB#1234` in the PR text).
   3. `#42` or `Fixes #42` in the PR title or body.
   4. The first number in the branch name (`feat/42-login` → 42).
   5. A `docs/blast-radius/*.md` file that the branch itself adds or changes (it is often committed with the work).
   6. `docs/blast-radius/branch-<branch>.md`.
   7. A file in `docs/blast-radius/` whose name shares 1+ word (not "feat", "fix", "add") with the branch name, the PR title, or the commit subjects. If only one report file exists, offer it. Ask: "Compare with <file>?"
   8. Else ask once: "I found no BEFORE report. Give me a ticket ID or a file, or I make an AFTER-only report."
3. **Measure the real impact.** Do steps 3-7 on the diff. Size what the diff **did**. Work the change still needs goes to **Missed** and to should-change findings, not into the sizes. Keep WHAT and WHY (from the ticket, else from the commit messages, tagged guess).
   - **Should have changed**: files the diff did not touch, but that describe what the diff changed (a contract doc, an API spec, a client in another repo). Also code the diff added that nothing uses (a migration no code runs). List them as findings.
   - Confidence for AFTER-only with no ticket: max **medium**.
4. **Compare** (skip for AFTER-only):
   - **Guess vs real**: one row per sized part. Guess size, real size, and the step difference ("same", "+1", "-1").
   - **WHAT check**: does the diff do what WHAT said? yes, partly, or no, and why.
   - **Hits**: files in the guess that changed. A "maybe" that changed is a hit.
   - **Surprises**: files that changed but were not in the guess. Say why, if you can see it.
   - **Missed**: files in the guess that did not change. Still to do, or a wrong guess?
   - **Accuracy**: hits / (hits + surprises + missed), as a percent. Do not count the report file, lock files, or vendored files.
   - **FIT check**: did the work follow the checklist from the BEFORE FIT section? If the BEFORE report is an older version of the template, read it as it is.
5. **Write** as the "Where the report goes" table says. In a file, add the "After" section under the BEFORE text. Do not change the BEFORE text.
