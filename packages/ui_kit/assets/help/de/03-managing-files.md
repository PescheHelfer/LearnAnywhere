# Arbeiten mit Dateien

Alles Dateibezogene liegt im Menü **Datei** (`Alt+D`). Dieses Kapitel geht der Reihe
nach jeden Befehl darin durch, dazu die beiden automatischen Abläufe — Statistiken
automatisch laden und automatisch speichern —, die einen Teil davon leise für Sie
erledigen.

## Lerneinheiten

- **Lerneinheiten laden...** öffnet eine `.vok`-Datei und ersetzt dabei alles, was
  gerade im Speicher ist.
- **Lerneinheiten hinzuladen...** fügt die Einheiten einer weiteren Lern-Datei an das
  Ende der bereits geöffneten an, statt sie zu ersetzen. Die hinzugeladene Datei muss
  dieselbe Maske verwenden; tut sie das nicht, oder würde das Angleichen an die aktuelle
  Maske Daten verlieren, wird das Hinzuladen verweigert, statt eine der beiden Dateien
  stillschweigend zu beschädigen.
- **Lerneinheiten speichern** schreibt in die geöffnete Datei zurück.
  **Lerneinheiten speichern unter...** schreibt in einen neuen Pfad und wechselt dorthin,
  die ursprüngliche Datei bleibt unangetastet.
- **Lerneinheiten im Speicher löschen...** leert den Arbeitsbereich. Nach der
  Bestätigung wählen Sie zwischen dem Laden einer vorhandenen Maskendatei für den
  Neuanfang oder dem Erstellen einer brandneuen Maske — Letzteres führt direkt in den
  [Mask Editor](05-mask-editor.md), um sie zu gestalten. Dieser Befehl rührt nichts auf
  der Festplatte an; er leert nur, was gerade geladen ist.

## Masken

- **Neue Masken-Datei laden...** lädt eine `.inf`-Datei als die mit der aktuellen
  Lern-Datei verknüpfte Maske. Dabei werden die derzeit geladenen Lerneinheiten
  geleert, da eine Maske die Form vorgibt, in die diese Einheiten passen müssen.
- **Masken-Datei speichern** / **Masken-Datei speichern unter...** schreiben die
  gerade bearbeitete Maske in ihre `.inf`-Datei. Es sind dieselben Befehle, die auch
  die OK-Schaltfläche des [Mask Editors](05-mask-editor.md) selbst verwendet.

Ist mit einer Lern-Datei noch keine Maskendatei verknüpft — etwa weil sie aus einer
spontan erstellten Maske gebaut wurde — bietet der Mask Editor beim Öffnen an, aus der
eingebetteten Kopie der Lern-Datei eine solche zu erstellen, damit künftige Änderungen
irgendwo gespeichert werden können.

## Statistik

- **Statistik laden...** / **Statistik speichern** / **Statistik speichern unter...**
  laden oder schreiben eine `.sta`-Datei für die aktuelle Lern-Datei.
- **Statistik löschen...** löscht nach Bestätigung jeden verzeichneten Versuch für die
  aktuelle Lern-Datei. Das lässt sich nicht rückgängig machen.

Diese vier Befehle finden sich auch auf dem Bildschirm [Statistik](09-statistics.md)
selbst wieder, sodass Sie ihn zum Sichern Ihrer Ergebnisse nie verlassen müssen.

## Automatisch laden und automatisch speichern

Zwei unabhängige Schalter unter **Optionen ▸ Statistiken** ersparen Ihnen den Weg über
das Menü Datei:

- **Statistiken automatisch laden** — beim Öffnen einer Lern-Datei sucht das Programm
  daneben nach einer passenden Sitzungsdatei mit Zeitstempel und fragt, falls es eine
  findet, ob sie geladen werden soll. Nichts wird stillschweigend geladen; Sie sehen
  vor der Entscheidung immer, wie alt die Datei ist und wie viel der Lern-Datei sie
  abdeckt.
- **Statistiken automatisch speichern** — startet eine Lernsitzung und ist der
  Lern-Datei noch keine Statistikdatei zugeordnet, wird automatisch eine angelegt,
  benannt nach der Lern-Datei und dem Moment des Sitzungsbeginns, im selben Ordner wie
  die Lern-Datei. Von da an wird Ihr Fortschritt fortlaufend hineingeschrieben, ohne
  weitere Rückfrage.

**Nur die letzten N Sitzungsdateien behalten...** (ebenfalls unter
**Optionen ▸ Statistiken**) begrenzt, wie viele dieser automatisch gespeicherten
Dateien sich pro Lern-Datei ansammeln: sobald mehr als die eingestellte Anzahl
vorhanden sind, werden nach jeder neu geschriebenen die ältesten gelöscht. Auf 0
gesetzt, werden alle Dateien behalten.

## Beenden

**Beenden...** fragt nach Bestätigung und speichert dann — falls automatisches
Speichern eingeschaltet ist — die Statistik ein letztes Mal, bevor das Programm
schließt. Die Schließen-Schaltfläche des Fensters (das X in der Titelleiste) durchläuft
genau denselben Ablauf, sodass sich die Ergebnisse einer Sitzung nicht dadurch
verlieren lassen, dass das Fenster statt des Menüs geschlossen wird.
