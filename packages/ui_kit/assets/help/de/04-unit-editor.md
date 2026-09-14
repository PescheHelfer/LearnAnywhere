# Lerneinheiten bearbeiten

Im Lerneinheiten-Editor schreiben Sie Ihr Material. Öffnen Sie ihn über
**Edit ▸ Eingabe-Maske** (`Alt+E`, dann `E`); er öffnet bei der zuletzt betrachteten
Lerneinheit.

Alles im Editor ist auf die Tastatur ausgelegt — dieselben Tasten funktionieren, ob Sie
gerade die Felder einer Karte betrachten oder zwischen Karten wechseln.

## Aufbau

Die Kopfzeile zeigt **"Einheit {index} von {total} - {category}"**, sodass Sie immer
wissen, wo Sie sich befinden und zu welcher Kategorie die aktuelle Karte gehört.
Darunter folgt eine Zeile pro Feld dieser Kategorie, jede mit dem Feldnamen und seinem
Wert.

Ein Feld ohne Namen ist ein **verdecktes Feld**: es enthält einen Wert, wird hier aber
nie als Zeile angezeigt — siehe [Grundbegriffe](02-concepts.md#kategorie-und-feld).

## Zwischen Einheiten wechseln

| Taste | Aktion |
|---|---|
| `F2` | Vorherige Einheit |
| `F3` | Nächste Einheit |
| `F6` | Zu einer bestimmten Einheitsnummer springen |
| `F5` | Alle Einheiten nach passendem Text durchsuchen |

**Springen** und **Suche** öffnen jeweils einen kleinen Dialog; die Suche zeigt jede
passende Einheit als Liste an, aus der direkt ausgewählt werden kann, oder meldet
**"Keine passenden Lerneinheiten gefunden."**, wenn nichts passt.

## Einheiten hinzufügen und entfernen

- `F8` — **Einfügen** vor der aktuellen Einheit. Hat die Maske mehr als eine Kategorie,
  werden Sie zuerst gebeten, eine **Kategorie zu wählen**.
- `F7` — **Löschen** der aktuellen Einheit, nach Bestätigung — das lässt sich nicht
  rückgängig machen.
- Ist die Lern-Datei völlig leer, zeigt der Editor statt einer Karte eine Schaltfläche
  **Einfügen**; es gibt nichts zu navigieren, bis die erste Einheit hinzugefügt wurde.

Hat die Maske selbst noch keine Kategorien, weist der Editor darauf hin und schickt Sie
zunächst in den [Mask Editor](05-mask-editor.md) — eine Kategorie muss existieren, bevor
ihr eine Einheit zugeordnet werden kann.

## Ein Feld bearbeiten

Klicken Sie in ein Feld und tippen Sie. Felder sind einzeilig und haben eine feste
Breite, bestimmt durch ihre **Länge** ([Grundbegriffe](02-concepts.md#kategorie-und-feld))
— was Sie eintippen, lässt die Zeile nie wachsen oder schrumpfen. `Enter` oder `Tab`
springt zum nächsten Feld; `Rücktaste` auf einem leeren Feld springt zum vorherigen
zurück.

### Formatierter Text

Markieren Sie Text innerhalb eines Feldes, um ihn zu formatieren:

| Aktion | Wirkung |
|---|---|
| Fett | **Fett** |
| Kursiv | *Kursiv* |
| Unterstrichen | Unterstrichen |
| Textfarbe | Färbt den markierten Text in der Textfarbe der Darstellung; erneutes Klicken entfernt sie |
| Markierung | Eine aus wenigen Hintergrundfarben für helle oder dunkle Darstellungen, oder Keine |
| Formatierung löschen | Entfernt Fett/Kursiv/Unterstrichen/Farbe/Markierung aus der Markierung |

**Textfarbe** funktioniert wie **Fett**: es gibt keine Farbauswahl, und die Schaltfläche
erscheint gedrückt, wenn der markierte Text schon gefärbt ist. Jede Darstellung bietet
genau eine Textfarbe, gewählt, damit sie auf deren Feldern gut lesbar bleibt und nie wie
die Farbe einer Korrekturmarke aussieht; das Symbol der Schaltfläche ist in ihr
gezeichnet. Die Lern-Datei speichert nur, *dass* der Text gefärbt ist, nicht die Farbe
selbst — ein Wechsel der Darstellung färbt ihn deshalb überall neu: im Editor, in einer
Lernsitzung und auf Android.

Ist nichts markiert, wirkt das Einschalten von Fett, Kursiv, Unterstrichen oder Textfarbe
auf den *nächsten* getippten Text — praktisch, um ein ganzes Wort kursiv zu tippen, ohne
es danach markieren zu müssen. Formatierung wird mit der Einheit gespeichert und bleibt
erhalten, wohin auch immer die Lern-Datei geht.

## Abschließen

- `F10` — **Fertig**. Behält jede vorgenommene Änderung und kehrt zum Arbeitsbereich
  zurück.
- `Esc` — **Abbruch**. Hat sich seit dem Öffnen des Editors nichts geändert, kehrt dies
  sofort zurück; hat sich etwas geändert, werden Sie gefragt, ob die Änderung verworfen
  werden soll, und die Lern-Datei kehrt genau in den Zustand zurück, in dem sie beim
  Öffnen des Editors war.

Nichts, was Sie im Lerneinheiten-Editor tun, schreibt von sich aus auf die Festplatte —
verwenden Sie **Datei ▸ Lerneinheiten speichern** (oder `F10` und anschließend
Speichern), sobald Sie mit dem Ergebnis zufrieden sind. Siehe
[Arbeiten mit Dateien](03-managing-files.md).
