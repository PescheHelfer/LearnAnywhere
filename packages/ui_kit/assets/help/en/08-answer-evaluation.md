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
match, even if what you did type is correct. In
[Level learning](07-level-learning.md) the scaffold fills part of every answer in for
you and those characters count as typed, so a scaffolded field never arrives empty
whichever way this option is set.

Fields sharing a non-zero [equal group](02-concepts.md#equal-group) are checked
together, so you may type their values in any order. Each value you type is compared
with the solution value it matches best, and that is also the value the **Almost**
similarity compares it with: swapping two rows never turns a near miss into a wrong
answer.

In **Correction**, an equal group appears in the order you typed it. Every row keeps its
own label and shows the solution value its entry was matched with, so after a swap with
one typo only the typo is marked. The **Solution** view always shows the deck's own
order.

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

A correct answer typed exactly as the deck stores it, character for character and in
the stored order (leading and trailing spaces aside), opens on **Solution**, and `F9`
leaves **Correction** out: there is nothing to mark. Every other answer opens on
**Correction**. Besides every **Wrong** and **Almost** answer, that includes a correct
answer whose equal-group rows you swapped, shown in your order with no marks, and one
that differs only in case or accents, with those characters marked. **Solution** keeps
the deck's order, so after a swap `F9` shows you how the deck stores it.

**Correction** marks every character in which your answer differs from the stored
solution, including case and accents that did not make it wrong because **Case
sensitive** or **Accent sensitive** is off: "Le lapin" against "le lapin" marks the L.
Leading and trailing spaces are never marked.

In **Correction**, an answer field with at least one mark drops the unit's own
**Text color**, **Highlight**, **Underline** and strikethrough, so they can't hide a
marked character or be mistaken for the marks of a missing or extra one. **Bold** and
**Italic** stay. A field with no marks, the question and remark fields, and the
**Solution** view keep all their formatting.

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
