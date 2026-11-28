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
3. **Measure the real impact.** Do steps 3-7 on the diff. Size what the diff **did**. Use the tables in scoring.md on the diff, also where a table speaks of what the change needs (Tests). Work the change still needs goes to **Missed** and to should-change findings, not into the sizes. Keep WHAT and WHY (from the ticket, else from the commit messages, tagged guess).
   - **Should have changed**: files the diff did not touch, but that describe what the diff changed (a contract doc, an API spec, a client in another repo). Also code the diff added that nothing uses (a migration no code runs). List them as findings.
   - Confidence for AFTER-only with no ticket: max **medium**.
4. **Look ahead.** Findings say what is wrong in the diff now. Look ahead says what the diff can cause later. Check the touched area plus one level out:
   - **ripple**: code outside the diff that now gets a different input, output, or call order (callers, jobs, other repos that read a changed contract). Say what it now sees.
   - **flow**: the path inside the changed code runs differently: a new step, branch, async path, or failure point, or a new order. Say what runs differently, and where it can fail.
   - **design**: a pattern, coupling, or shortcut that the next change will copy or must work around (a second way to do X, data that two modules now own, a hard-coded limit).
   - **growth**: what breaks when data, users, or calls grow (a full scan per request, an in-memory store, no paging, a list with no limit).
   - **next**: the change that the ticket or the code points to next. Does this diff make it easy or hard? This item may sit in another repo, or in a file the diff does not touch.
   - ripple or flow? When the code that gets hit is outside the diff, it is ripple.

   Each item gets an ID (A1, A2, ...), a kind, a place (`file:line`), what can happen, **when** it bites (the trigger), and one action: `now: <fix>` or `watch: <signal>`. Max 5. Put "next" items first (they are near certain), then the others, most likely first. Tag each item (often **guess**). When a probe proved the fact under the risk, tag that fact **run**.
   - **When** names a thing a person can see: a number ("over ~100k notes"), a PR or ticket ("the notes-web tag PR"), or an event ("the store moves to SQLite"). Not "many notes" or "later".
   - Only risks that are not bugs today. A bug today is a finding (F). Do not list it twice.
   - An item may build on a finding only when it names a cost that the finding does not name (finding: "unused migration"; item: "tags then live in two places"). Add "see F6". The same file or the same problem is not a new cost.
   - When the action is already a finding's fix, write `now: see F2`. Do not write the fix again.
   - An item with no new cost and only `now: see F<n>` as its action is a repeat. Leave it out.
   - Nothing real: write "none seen" and one reason. Do not fill the list to fill it.
5. **Compare** (skip for AFTER-only):
   - **Guess vs real**: one row per sized part. Guess size, real size, and the step difference ("same", "+1", "-1").
     - When the BEFORE Notes named a size for a case ("L if X") and the diff took that case, compare with that size, not the main size. Write the guess as "L (if X)" and say in Notes: "guess for X was L". The overall guess stays as BEFORE wrote it.
     - When the real size is smaller only because work is not done yet, write the difference as "-1, still to do". Start Notes with "Still to do:" and name the Missed file or the finding. This is not a guess error.
   - **WHAT check**: does the diff do what WHAT said? yes, partly, or no, and why.
   - **Hits**: files in the guess that changed. A "maybe" that changed is a hit.
   - **Surprises**: files that changed but were not in the guess. Say why, if you can see it.
   - **Missed**: files in the guess that did not change. Still to do, or a wrong guess? A "maybe" that did not change is Missed only when its "if" came true and the file still needs the change.
   - **Maybe, not changed**: the other "maybe" files that did not change. List them on their own line. They are not Missed, and they do not count in accuracy.
   - **Questions**: for each BEFORE open question, say if the diff answered it (and how) or it is still open. The chat summary counts the open ones.
   - **Accuracy**: hits / (hits + surprises + missed), as a percent. Do not count the report file, lock files, or vendored files.
   - **FIT check**: did the work follow the checklist from the BEFORE FIT section? If the BEFORE report is an older version of the template, read it as it is.
6. **Merge score.** Count it with the rule in scoring.md ("Merge score"). Use the header counts of new findings, also the ones not in the table. Give the score, the call, the bug risk, and the math line.
7. **Write** as the "Where the report goes" table says. In a file, add the "After" section under the BEFORE text. Do not change the BEFORE text.
