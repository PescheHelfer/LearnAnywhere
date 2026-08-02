# Working with files

Everything file-related lives on the **File** menu (`Alt+F`). This chapter walks
through every command on it, in order, plus the two automatic behaviours — auto-load
and auto-save statistics — that quietly do some of this for you.

## Decks

- **Load deck...** opens a `.vok` file, replacing whatever is currently in memory.
- **Add/merge deck...** adds another deck's units onto the end of the one you have
  open, instead of replacing it. The merged deck must use the same mask; if it does not,
  or if bringing it in line with the current mask would lose data, the merge is refused
  rather than silently damaging either file.
- **Save deck** writes back to the file you opened. **Save deck as...** writes to a new
  path and switches to it, leaving the original file untouched.
- **Clear units from memory...** empties the workspace. After confirming, you choose
  between loading an existing mask file for the fresh start or minting a brand-new mask
  — the latter drops you straight into the [mask editor](05-mask-editor.md) to shape it.
  Nothing on disk is touched by this command; it only clears what is currently loaded.

## Masks

- **Load mask...** loads an `.inf` file as the mask linked to the current deck. This
  clears the units currently in memory, since a mask defines the shape those units must
  fit.
- **Save mask** / **Save mask as...** write the mask you are editing to its `.inf` file.
  These are the same commands the [mask editor](05-mask-editor.md)'s own OK button uses.

If a deck has no mask file linked to it yet — for instance because you built it from a
mask minted on the spot — opening the mask editor offers to create one from the deck's
embedded copy, so future edits have somewhere to be saved.

## Statistics

- **Load stats...** / **Save stats** / **Save stats as...** load or write a `.sta` file
  for the current deck.
- **Clear stats...** erases every recorded attempt for the current deck, after
  confirming. This cannot be undone.

These four are duplicated on the [Statistics](09-statistics.md) screen itself, so you
never have to leave it to save your results.

## Auto-load and auto-save

Two independent toggles under **Options ▸ Statistics** save you the trip to the File
menu:

- **Auto-load statistics** — when you open a deck, the program looks beside it for a
  matching timestamped session file and, if it finds one, asks whether to load it.
  Nothing is loaded silently; you always see how old the file is and how much of the
  deck it covers before deciding.
- **Auto-save statistics** — when a learning session starts, if no statistics file is
  already associated with the deck, one is created automatically, named after the deck
  and the moment the session began, in the deck's own folder. From then on your
  progress is written to it as you go, without any further prompting.

**Keep last N session files...** (also under **Options ▸ Statistics**) bounds how many
of these auto-saved files pile up per deck: once you have more than the configured
count, the oldest are deleted after each new one is written. Set it to 0 to keep every
file.

## Exit

**Exit...** asks for confirmation, then — if auto-save is on — saves your statistics one
last time before closing. The window's own close button (the X in the title bar) goes
through exactly the same sequence, so there is no way to lose a session's results by
closing the window instead of using the menu.
