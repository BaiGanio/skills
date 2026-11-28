# Scoring

Security is sized in [quality.md](quality.md). Findings (FIT and HEALTH) are not sized. They have a severity.

Each sized part gets S, M, L, or XL. Find the biggest fact for that part. Pick the size whose text names that fact. Give one reason per size.

- Between two sizes: pick the lower one, and say why it is not the higher one.
- Size depends on an open choice: size the simplest choice that meets the ticket, and write "L if <other choice>".
- Size the work for **this change**, not the state of the whole repo.
- In AFTER, size what the diff did (after.md step 3). Example: a diff that adds 1 small test is Tests **S**, also when the change needs **L**. The rest is "still to do".

## Files

Count files in change + new + delete. Do not count "maybe", lock files, generated files, or vendored third-party copies (fonts, libraries). Show them apart.

| Size | Files |
|---|---|
| S | 1-3 |
| M | 4-10 |
| L | 11-30 |
| XL | 31+ |

Then the repo rule: 2 repos with real work in each (not only a config line): at least **L**. 3 or more: **XL**.

## Design (inside modules)

A new route or endpoint counts under Contracts, not Design. In Design, only count the code shape behind it.

| Size | Meaning |
|---|---|
| S | Logic or text change. No new types, no signature change. |
| M | New function, class, or component in an existing pattern. Internal signature changes. |
| L | A new pattern, or a public interface of a module changes. Callers must change. |
| XL | Many modules get a new shape. A rewrite. |

## Architecture (between modules)

| Size | Meaning |
|---|---|
| S | No change in layers, dependencies, or data flow. |
| M | A new dependency between two existing modules, or a new small library. |
| L | A new module, a new external service or package with weight, a new data flow, or a new store table that code uses. (A table or config that no code uses is a finding, not L.) |
| XL | A new service, a new data store, a new deploy unit, or a change in how repos talk to each other. |

## Contracts (facts other code or repos read)

Example: an API response gets a new optional `tags` field. If no client must change to keep working, and no client uses it in this ticket: **M**. If a client in this ticket starts to use it, or the contract doc must change: **L**. If an old client breaks: **XL**. A new client of an existing endpoint, with no change to the endpoint: **M**.

| Size | Meaning |
|---|---|
| S | None. |
| M | An internal contract changes (a module API used only in this repo), or a public API gets an optional field that no client must use yet. |
| L | A public API, schema, event, or config key changes, and old clients still work. |
| XL | A breaking change, or a shared fact changes: URL, domain, auth (issuer, audience, client ID, roles), CORS origin, DB schema used by others. |

## Risk (what can break)

| Size | Meaning |
|---|---|
| S | Docs, text, styles, dev tools. Users see no change if it breaks. |
| M | Business logic with tests around it. A bug is easy to see and fix. |
| L | Auth, payments, data writes, migrations, config, CI, or code with no tests. |
| XL | The production deploy path, security, possible data loss, or a change that many users hit at once. |

Old loss paths: when a new crash can reach a data loss that old code can already cause (for example a crash that wipes an in-memory store, and bad JSON already crashes it), Risk is at most **L**. Name the old path in Notes: "Not XL: the loss path is old (<F-ID>)". This is the same rule as for Security size (quality.md).

## Tests

| Size | Meaning |
|---|---|
| S | Existing tests cover it, or the change is so small that one tiny test (or none) is enough. Say which. |
| M | Some tests change, and a few new tests. |
| L | This change needs a new test suite (for example the first route tests), or many tests. Old gaps that this change does not need are "Now:" findings, not L. |
| XL | No test setup exists for an area this change needs tested. It must be built first. |

Many repos: size each repo, then take the biggest. Name the repo in the reason.

## Rollback

| Size | Meaning |
|---|---|
| S | `git revert` and deploy. Done. |
| M | Revert plus a config or flag change, or undo an additive schema change that holds no data yet. |
| L | Revert in an order across repos where the wrong order hurts users for more than a short time, or undo a data migration that holds data. |
| XL | One-way: data deleted, a message sent, a public API removed, or something published. |

## Overall size

1. Start with the biggest size among Files, Design, Architecture, Contracts, Risk, and Security.
2. If Rollback is XL or Security is XL, the overall size is XL.
3. If 4 or more of those 6 parts are L, the overall size is XL.
4. Tests do not change the overall size. They show in the report as work to plan.
5. If the overall size is XL, suggest how to split the ticket (by repo, by layer, or by part of the plan).

Rough meaning, for the reader:
- **S**: hours. One reviewer.
- **M**: a day or two. One reviewer.
- **L**: days. Two reviewers, or one who knows the area well. Plan the order of the work.
- **XL**: a week or more. Split the ticket, or write a plan first.

## Confidence

- **high**: you saw every file in the list, and the ticket is clear.
- **medium**: you saw most files. Some groups are guesses.
- **low**: the ticket is vague, or the code is too big to check. Say what would make it higher.

## Merge score (AFTER mode)

One number for the PR, from a fixed rule. It is a **score, not a chance**. Never write it as "safe" or "likely". The same findings must always give the same score.

1. Start at 100.
2. Take off for each **new** finding (the diff added it; should-change counts): high -25, medium -10, low -3. "Now:" findings take off nothing: the PR did not add them.
3. WHAT check: partly -10, no -30. Skip this when new findings already name every missing part (no double count), or in AFTER-only with no WHAT check.
4. With `--run-checks`: -20 if a test, lint, or audit fails. Not run: 0.
5. The lowest score is 0.
6. Any new high finding: the score is at most 49.

| Score | Call |
|---|---|
| 80-100 | ready |
| 50-79 | fix first: <the findings to fix> |
| 0-49 | not ready: <the findings to fix> |

**Bug risk**, next to the score: **high** when a new high finding of kind bug or security exists, **medium** when a new medium one exists, else **low**. Name the IDs and the best tag (`high (F1, run)`).

Show the math in one line: `100 - 25 (F1) - 10 x 5 (F2-F6) - 3 (F7) - 10 (WHAT partly) = 12`.

## Accuracy (AFTER mode)

- Size steps: S→M is 1 step, S→L is 2 steps.
- File accuracy: hits / (hits + surprises + missed), as a percent.
- 80%+ is good. 50-79% is fair. Under 50%: say what the guess missed, so the next guess is better.
