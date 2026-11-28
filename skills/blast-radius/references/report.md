# Report template

Fill the template. Remove lines that do not apply. Keep the order.
The HTML comments are markers. Keep them exactly. The skill finds old reports with them.
Only the top box, the impact map, and the open questions are open. All other sections are closed `<details>` blocks.

## BEFORE

```markdown
<!-- blast-radius:before id=<ticket-id> version=<n> date=<YYYY-MM-DD> -->
## Blast radius: <title>

**Size <S|M|L|XL>** · confidence <high|medium|low> · <n> file(s) · <n> repo(s) · security <S|M|L|XL> · now <n> high, <n> medium, <n> low · new <n> high, <n> medium, <n> low · source: <link or "text">

> **WHAT**: <the goal in one sentence>. Done when <check>.
> **WHY**: <the problem and who feels it>. <(guess) if not in the ticket>
> **Other way**: <a simpler way, or "none seen">
> **Depends on**: <work outside the change list that must come first, or leave this line out>
> **Already done**: <parts of the ticket that are already in the code, or leave this line out>
> **Scope change since v<n>**: <what the new ticket text adds or drops, or leave this line out>
> **Top findings**: F1 <one line> · F2 <one line> · F3 <one line>

### Impact map

<diagram 1, or the one-line form>

<sub>Green S · yellow M · orange L · red XL · grey no change</sub>

### Open questions

1. <question for the ticket author>

<details><summary>Impact: size per part</summary>

| Part | Size | Notes |
|---|---|---|
| Files | <size> | <n> change, <n> new, <n> delete, <n> maybe (seen) |
| Design | <size> | <reason> (seen) |
| Architecture | <size> | <reason> |
| Contracts | <size> | <reason, or "none"> |
| Risk | <size> | <reason> |
| Security | <size> | <reason; findings: F2> |
| Tests | <size> | <reason> |
| Rollback | <size> | <reason and order of undo> |

Overall: <one line: which rule gave the size>. <If XL: how to split the ticket.>

<diagram 2, if needed>

<diagram 3, if needed>

</details>

<details><summary>Fit: project rules (plan: <n> follow, <n> break, <n> unclear)</summary>

Sources: <files found>. Not found: <for example "no ADRs, no lint config">.

| Rule | Source | Now | Plan | Where |
|---|---|---|---|---|
| <rule> | `.blast-radius/standards.md` (must) | breaks (F3) | follows if <what the work must do> | `file:line` |

</details>

<details><summary>Findings: health and security (<n>)</summary>

| ID | Sev | Kind | Where | What | Fix |
|---|---|---|---|---|---|
| F1 | high | security | `file:line` | Now: <what> (run) | <fix> |

Reuse: <existing code to reuse, with file:line, or leave out>

</details>

<details><summary>Files (<n>)</summary>

| Group | File | Why | Tag |
|---|---|---|---|
| change | `path/to/file` | <reason> | seen |
| change | `other-repo/path/file` | <reason> | seen |
| new | `path/to/new` | <reason> | guess |
| maybe | `path/to/other` | <if we choose X> | guess |

Not changed (seen): <files a reader may expect to change but do not, or leave this line out>

</details>

<details><summary>History</summary>

<older versions, newest first, each under a line "**Version <n>, <date>**">

</details>

<sub>Made by blast-radius v0.6.2</sub>
```

If there is no older version, leave out the History block.

## AFTER

In file mode, add this under the BEFORE text. In comment mode, this is the whole PR comment.

```markdown
<!-- blast-radius:after id=<ticket-id> version=<n> date=<YYYY-MM-DD> -->
## Blast radius AFTER: <title>

**Merge score <n>/100** (<ready|fix first|not ready>) · **Size <real>** (guess was <guess>) · confidence <high|medium|low> · accuracy <n>% · <n> file(s) · <n> repo(s) · security <size> · findings <n> high, <n> medium, <n> low · now <n> high, <n> medium, <n> low · PR: <link, or "branch <name> (no PR)">

> **Merge score**: <n>/100, <call>. Bug risk: <high|medium|low> (<IDs, tag>). <Fix first: F1, F3>
> **WHAT check**: <yes / partly / no>. <why, one line>
> **FIT check**: <n> of <n> rules followed. <the worst break, or "all followed">
> **Biggest surprise**: <one line>
> **Top findings**: F1 <one line> · F2 <one line> · F3 <one line>
> **Look ahead**: A1 <one line> · A2 <one line> (max 2), or "none seen: <reason>"

### Impact map (real)

<diagram from the diff; surprises dashed; still to do dotted (`todo`)>

<details><summary>Guess vs real</summary>

| Part | Guess | Real | Diff | Notes |
|---|---|---|---|---|
| Files | M | L | +1 | <reason> |
| Design | ... | ... | ... | ... |
| Architecture | ... | ... | ... | ... |
| Contracts | ... | ... | ... | ... |
| Risk | ... | ... | ... | ... |
| Security | ... | ... | ... | ... |
| Tests | L | S | -2, still to do | Still to do: <the missing work> (<Missed file or F-ID>) |
| Rollback | ... | ... | ... | ... |

- Hits (<n>): `a`, `b`
- Surprises (<n>): `c` (<why>)
- Missed (<n>): `d` (<still to do, or wrong guess?>)
- Maybe, not changed (<n>): `e` (<why it is not needed yet>)
- Questions still open (<n>): <BEFORE question numbers, each with a short why, or "none">. Answered: <numbers, with how>
- Not committed (<n>): `f`
- Checks: <tests / lint / audit: pass, fail, or "not run (no --run-checks)">

</details>

<details><summary>Fit: project rules (<n> follow, <n> break)</summary>

| Rule | Source | Diff | Where |
|---|---|---|---|
| <rule> | <source> | follows / breaks (F2) | `file:line` |

</details>

<details><summary>Findings: health and security (<n>)</summary>

<same table as BEFORE. Kinds include should-change. Add "Fixed by this diff: <old smells now gone>". Add "Still open from BEFORE, outside the touched area: <BEFORE IDs, short>" when there are any.>

</details>

<details><summary>Merge score: how it was counted</summary>

`<the math line, for example 100 - 25 (F1) - 10 x 2 (F3, F4) - 10 (WHAT partly) = 45>`

<Only when the cap lowered the score: "Capped at 49: new high finding F1.">
A score from the rule in scoring.md, not a chance. "Now:" findings do not count.

</details>

<details><summary>Look ahead: risks for later (<n>)</summary>

| ID | Kind | Where | What can happen | When | Do |
|---|---|---|---|---|---|
| A1 | next | `file:line` | <what> (seen) | <a PR, ticket, or event> | now: <fix> |
| A2 | growth | `file:line` | <what> (guess) | <a number, for example "over ~100k notes"> | watch: <signal> |

</details>

<sub>Made by blast-radius v0.6.2</sub>
```

### AFTER-only (no BEFORE report)

- In the header: leave out "guess was" and accuracy. Keep the merge score (no WHAT part, see scoring.md).
- In the top box: put **WHAT** and **WHY** (from the ticket, or tagged guess) instead of "WHAT check" and "Biggest surprise". Keep "FIT check", "Top findings", and "Look ahead".
- Add an "Open questions" section after the impact map, like in BEFORE.
- Do not use the dashed "surprise" style. Use `todo` for should-change files and repos.
- Replace "Guess vs real" with "Impact: size per part" from the BEFORE template, using a "Real" column.
- Add a closed "Files" block like in BEFORE.

## Link comment on the issue (AFTER, issue mode)

```markdown
<!-- blast-radius:after-link id=<ticket-id> -->
Blast radius AFTER for <PR link>: merge score <n>/100 (<call>), size <real> (guess <guess>), accuracy <n>%, findings <n> high, look ahead <n>.
```

## History

On a re-run, keep a short copy of the old version in the History block: its header line, its top box, and its "Impact: size per part" table. Leave out its marker, its diagrams, its other `<details>` blocks, and its footer. Put "**Version <n>, <date>**" above it. Raise `version` in the new marker.
Keep max 3 old versions. Drop the oldest.
Write the whole file in one write, with the full new content. Do not append command output.
