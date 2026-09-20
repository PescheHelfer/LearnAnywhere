# Mobile — glossary

The vocabulary `packages/mobile` owns. This is a glossary and nothing else: it says
what a term means and what it is not, never how it is implemented or what the product
should do.

Use these words as written. If a concept you need is not here, either you are inventing
language the project does not use, or there is a real gap worth adding.

**Library** — the companion's on-device folder of decks, enumerated fresh each time the
learner visits the screen. Not the desktop's *recent decks*, which is a short persisted
list of paths the learner has opened; the phone keeps no such list. German:
**Bibliothek**.

**Deck title** — the name a deck is shown under: its file's base name, without the
extension. Never the name of its mask — several decks can be built from one mask, and
naming them by it makes them indistinguishable. The mask's name appears only as the
Library row's subtitle, where the learner chooses between decks.
