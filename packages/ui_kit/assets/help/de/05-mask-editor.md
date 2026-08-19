# Der Mask Editor

Der Mask Editor gestaltet die *Form* Ihrer Karten — siehe [Grundbegriffe](02-concepts.md),
falls Sie das noch nicht gelesen haben. Öffnen Sie ihn über **Edit ▸ Mask Editor**
(`Alt+E`, dann `M`). Er bearbeitet immer die **verknüpfte `.inf`-Datei**, nie die
eigene eingefrorene Kopie einer Lern-Datei.

Hat die aktuelle Lern-Datei noch keine verknüpfte `.inf`, bietet der Editor beim Öffnen
an, eine solche aus der eingebetteten Kopie der Lern-Datei zu erstellen, damit es einen
Ort gibt, an dem Änderungen gespeichert werden können.

## Name und Abfragerichtungen

Oben: der **Maskenname** und die beiden **Namen der Abfragerichtungen** — die Namen,
die für jede Richtung im gesamten übrigen Programm angezeigt werden, zum Beispiel auf
dem [Einrichtungsbildschirm](06-learning-sessions.md).

## Kategorien

Das Feld **Kategorien** listet jede Kategorie auf, bis zu `maxCategoriesPerMask = 20`
Stück (live angezeigt als **"Kategorien: {count}/20"**). Für jede:

- **Kategorie hinzufügen** fügt eine neue, leere hinzu.
- Eine Kategorie auswählen, um sie umzubenennen — Namen sind auf 40 Zeichen begrenzt.
- **Nach oben** / **Nach unten** ordnen Kategorien um; die Reihenfolge wirkt sich nur
  darauf aus, in welcher Reihenfolge sie beim
  [Einfügen einer Einheit](04-unit-editor.md#einheiten-hinzufgen-und-entfernen)
  angeboten werden.
- **Kategorie klonen** fügt direkt nach der geklonten Kategorie eine Kopie ein, benannt
  nach ihr mit angehängtem "(Kopie)", und wählt die Kopie aus, damit sie sofort
  umbenannt werden kann. Die Felder der Kopie sind unabhängig — neue Feld-Identitäten,
  sodass das Bearbeiten der einen Seite die andere nie berührt —, enthalten aber keine
  Einheiten; kopiert wird das *Schema*, keine Daten. Nicht verfügbar, sobald die Maske
  die Kategorie-Obergrenze erreicht hat, genau wie **Kategorie hinzufügen**.
- **Kategorie löschen** entfernt sie. Verwendet noch eine Einheit diese Kategorie, ist
  das eine der Änderungen, die beim Speichern
  [bestehende Lern-Dateien beschädigen](#lern-dateien-synchron-halten) können.

## Felder

Eine Kategorie auswählen öffnet ihr Feld-Panel **Felder**, bis zu
`maxFieldsPerCategory = 20` Stück (**"Felder: {count}/20"**). Jedes Feld hat:

| Spalte | Bedeutung |
|---|---|
| Feldname | Leer macht das Feld verdeckt — siehe [Grundbegriffe](02-concepts.md#kategorie-und-feld) |
| Länge | 1 bis 80 Zeichen |
| Gruppe | Die Gleichheitsgruppe des Feldes — 0 bedeutet keine |
| Rolle Abfr. 1 / Rolle Abfr. 2 | `Q`, `A` oder `R` in jeder Richtung — siehe [Grundbegriffe](02-concepts.md#rolle-als-was-ein-feld-abgefragt-wird) |

**Feld hinzufügen**, **Feld löschen** sowie **Nach oben** / **Nach unten** funktionieren
wie bei Kategorien. Eine Feldlänge so zu verkürzen, dass vorhandene Daten abgeschnitten
würden, oder ein Feld mit Daten zu löschen, sind ebenfalls Änderungen, die bestehende
Lern-Dateien beschädigen können.

## Speichern: abspalten oder direkt aktualisieren

Beim Speichern einer Maske, die bereits von einer oder mehreren Lern-Dateien verwendet
wird, wählen Sie, wie:

- **Als neue Maske speichern** ("abspalten") vergibt der gerade bearbeiteten Maske eine
  brandneue Identität; jede bestehende Lern-Datei bleibt genau so, wie sie war, weiterhin
  an das Original gebunden. War die gerade geöffnete Lern-Datei aus dieser Maske gebaut,
  werden Sie gefragt, ob *sie* mit der Abspaltung neu verknüpft werden soll — jede
  andere Lern-Datei bleibt in jedem Fall unangetastet.
- **Direkt speichern** behält dieselbe Identität. Ist jede Änderung ungefährlich — nichts
  gelöscht, nichts über vorhandene Daten hinaus verkürzt — aktualisieren sich Lern-Dateien
  automatisch beim nächsten Öffnen, oder sofort über
  [Andere Kopien dieser Maske aktualisieren](#lern-dateien-synchron-halten) weiter unten.
  **Würde** eine Änderung eine oder mehrere Lern-Dateien beschädigen, wird genau
  gezeigt, welche und warum (eine gelöschte Kategorie macht Einheiten heimatlos, ein
  gelöschtes Feld verwirft ihre Daten, ein verkürztes Feld würde sie abschneiden), und
  Sie wählen: stattdessen abspalten, abbrechen, oder **die Aktualisierung erzwingen und
  den aufgeführten Datenverlust in Kauf nehmen**.

Der Titel des Mask Editors zeigt **"Noch nicht in einer Maskendatei gespeichert"** für
eine Maske, die noch nie auf die Festplatte geschrieben wurde.

## Lern-Dateien synchron halten

Das Bearbeiten der verknüpften `.inf` rührt für sich genommen keine Lern-Datei an — jede
behält ihre eigene eingefrorene Kopie, bis ausdrücklich anders angewiesen.
**Edit ▸ Andere Kopien dieser Maske aktualisieren...** durchsucht einen von Ihnen
gewählten Ordner nach jeder weiteren aus derselben Maske gebauten Datei und meldet für
jede den Status:

| Status | Bedeutung |
|---|---|
| Aktuell | Entspricht bereits dieser Maske |
| Wird aktualisiert | Weicht ab und kann gefahrlos auf den neuesten Stand gebracht werden |
| Würde beschädigen | Weicht so ab, dass beim Anwenden Daten verloren gingen |
| Abweichend (gleiche Revision) | Gleiche Revisionsnummer, aber anderer Inhalt — ungewöhnlich; vor dem Anwenden prüfen |
| Neuer (wird nicht überschrieben) | Die eigene Kopie der Lern-Datei ist aktueller als diese und bleibt unangetastet |

Wählen Sie die gewünschten aus und klicken Sie auf **Auswahl aktualisieren**. Nicht
Ausgewähltes bleibt unangetastet. Werden im gewählten Ordner keine weiteren Kopien
gefunden, wird das gemeldet, statt Sie im Unklaren zu lassen.
