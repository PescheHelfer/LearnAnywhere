# How answers are judged

Every checked answer gets one of three outcomes, and every outcome offers you a row of
rating buttons (`F5`/`F6`/`F7`) to have the final say. This chapter covers both halves:
what the program decides on its own, and what you can override.

All the options mentioned here live under **Options ▸ Advanced Learning Options** — see
[Settings](11-settings.md#learning-options) for the full list and where they are stored.

## Matching your answer to the solution

Before comparing, both your answer and the solution are **normalized**:

- Leading and trailing spaces are trimmed.
- Unless **Case sensitive** is on, both are lowercased.
- Unless **Accent sensitive** is on, accents are stripped (é → e, ü → u, and so on).

If **Complete input required** is on (the default), every field with a non-empty
solution must be filled in — an answer missing one of several required fields does not
match, even if what you did type is correct.

Fields sharing a non-zero [equal group](02-concepts.md#equal-group) are checked
together: any field in the group matching the corresponding solution field is accepted
as an answer for it.

## The three outcomes

- **Correct** — your normalized answer matches the solution exactly.
- **Almost** — only possible if **Accept near-misses as 'Almost'** is on. A close but
  not exact answer, at or above the **'Almost' similarity threshold (%)** (80% by
  default), is flagged as a near miss instead of an outright wrong answer.
- **Wrong** — anything else.

On reveal, the answer area can show your answer with differences against the solution
highlighted (**Correction**), the plain **Solution**, or **Your answer** unmarked — cycle
between them with `F9` during a session; see
[Learning sessions](06-learning-sessions.md#during-a-session).

## Rating the attempt

After a check, a row of up to three buttons lets you confirm or overrule the automatic
outcome. Which buttons appear depends on what happened:

| Situation | Buttons offered |
|---|---|
| No typed answer (self-judged) | **Knew it** · **Didn't know** · **Don't count** |
| Outcome: Correct | **Correct** · **Actually wrong** · **Don't count** |
| Outcome: Almost | **Wrong** (preselected) · **Close enough** · **Don't count** |
| Outcome: Wrong | **Wrong** · **Actually correct**\* · **Don't count** |

\* Only offered if **Wrong input correctable** is on — turn it off if you never want a
typo to be quietly overridden into a correct attempt.

**Close enough** records the attempt as correct, same as the program's own "Correct."
**Don't count** discards the attempt entirely — neither counted nor recorded — useful
for a card you clearly mistyped for reasons that have nothing to do with knowing the
answer.

## Guardrails

- **Minimum-attempts guard**, with a **Minimum attempts** value, prevents a unit from
  counting as mastered on a lucky first try — it must also have been attempted at least
  this many times.
- **Wrong-answer ceiling**, with a **Wrong-answer ceiling value**, stops adding to a
  unit's wrong count once it has accumulated that many — useful if you would rather a
  handful of early mistakes not dominate its long-term accuracy forever.

Both are off by default.
