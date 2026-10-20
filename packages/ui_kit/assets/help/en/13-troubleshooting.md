# Troubleshooting

Most of what looks like an error is the program refusing to guess at your behalf when
two files disagree. This chapter explains the messages you are most likely to run into
and what to do about each.

## "Cannot merge: the selected deck belongs to a different mask."

**Add/merge deck...** ([Working with files](03-managing-files.md#decks)) only combines
decks that share a mask. If they do not, merging them would produce units that do not
fit either mask's shape. Load the deck on its own instead, or bring both under one mask
first in the [mask editor](05-mask-editor.md).

## "Cannot merge: updating the added units to the current mask would lose data."

The decks do share a mask, but at different revisions, and bringing the incoming units
up to the current revision would drop or truncate some of their data. Update the mask
copy in the *other* file first with
[Update other copies of this mask](05-mask-editor.md#keeping-decks-in-sync), then merge.

## "The found units belong to different masks and cannot be loaded together." / "Loading the found units would lose data..."

The same two situations, met while
[loading Lexicon file-search results](10-lexicon.md#search-files) instead of merging.
The fix is the same: bring the source files onto a common, current mask first.

## "This deck's linked mask file has changed in a way that would lose data, so the deck keeps its own copy of the mask."

You opened a deck whose linked `.inf` was edited elsewhere in a breaking way since the
deck was last saved. Rather than silently adopting a change that would damage the
deck's units, the deck keeps its own frozen copy and tells you so. Open
**Edit ▸ Mask Editor** to see and resolve the difference deliberately.

## A mask-editor save wants to "fork," "cancel," or "force"

This is the [breaking-change prompt](05-mask-editor.md#saving-fork-or-update-in-place):
saving would break one or more decks that use this mask. Fork if you want the decks
left alone; force only if you are certain about the data loss; cancel to rethink the
edit.

## The mode-switch prompt at the start of a session

Covered in [Learning sessions](06-learning-sessions.md#the-four-modes) — it appears
because your existing statistics were recorded on the other side of the
Level-Learning divide from the mode you just picked. **Start fresh** is the only
option here that discards anything, and it says so before you confirm it.

## My statistics are not being saved automatically

Auto-save is off by default — turn it on at **Options ▸ Statistics ▸ Auto-save
statistics**. It also needs the deck to have been saved to a real path at least once:
an unsaved, in-memory-only deck has no folder to create a statistics file in. See
[Working with files](03-managing-files.md#auto-load-and-auto-save).

## My statistics are gone after updating

Since version 1.2.0 statistics files are kept in a folder named `statistics` beside each
deck, and only that folder is read. Files an older version wrote directly beside the
deck are still there, untouched, but the program no longer finds them, so the deck shows
as **not learned yet** and its lifetime record looks empty. Move each deck's `.sta` files
into the `statistics` folder beside it, keeping their names, and reopen the deck. See
[Working with files](03-managing-files.md#statistics).

## I made a mess in the unit editor or mask editor and want to start over

Press `Esc`. If you changed anything since opening the editor, you are asked to confirm
discarding it; confirming reverts everything to exactly how it was the moment you
opened the editor — not to the last saved file, but to that snapshot. If you already
pressed **Done** or saved, the change is final; there is no further undo.

## Search directory does not exist

Shown by the Lexicon's [file search](10-lexicon.md#search-files) when the folder you
picked has since been moved, renamed, or deleted. Pick the folder again.

## Nothing here matches what I am seeing

If a screen behaves unexpectedly and none of the above explains it, `Esc` back to the
workspace and re-open what you were doing — most screens rebuild their state fresh from
the current deck, mask and statistics rather than carrying anything hidden forward.
