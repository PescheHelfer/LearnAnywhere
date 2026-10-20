# Problembehebung

Das meiste, was wie ein Fehler aussieht, ist das Programm, das sich weigert, an Ihrer
Stelle zu raten, wenn zwei Dateien nicht übereinstimmen. Dieses Kapitel erklärt die
Meldungen, denen Sie am ehesten begegnen, und was jeweils zu tun ist.

## „Hinzuladen nicht möglich: Die gewählte Lern-Datei gehört zu einer anderen Maske.“

**Lerneinheiten hinzuladen...** ([Arbeiten mit Dateien](03-managing-files.md#lerneinheiten))
verbindet nur Lern-Dateien, die sich eine Maske teilen. Tun sie das nicht, würde das
Zusammenführen Einheiten erzeugen, die in keine der beiden Maskenformen passen. Laden
Sie die Lern-Datei stattdessen für sich allein, oder bringen Sie zuerst beide im
[Mask Editor](05-mask-editor.md) unter eine gemeinsame Maske.

## „Hinzuladen nicht möglich: Das Angleichen der hinzugefügten Einheiten an die aktuelle Maske würde Daten verlieren.“

Die Lern-Dateien teilen sich zwar eine Maske, aber in unterschiedlichen Revisionen, und
das Angleichen der hinzukommenden Einheiten an die aktuelle Revision würde einen Teil
ihrer Daten verwerfen oder abschneiden. Aktualisieren Sie zuerst die Maskenkopie in der
*anderen* Datei mit
[Andere Kopien dieser Maske aktualisieren](05-mask-editor.md#lern-dateien-synchron-halten),
dann laden Sie hinzu.

## „Die gefundenen Einheiten gehören zu unterschiedlichen Masken...“ / „Das Laden der gefundenen Einheiten würde Daten verlieren...“

Dieselben zwei Situationen, hier beim
[Laden von Lexikon-Dateisuchergebnissen](10-lexicon.md#dateien-durchsuchen) statt beim
Hinzuladen. Die Lösung ist dieselbe: die Quelldateien zuerst auf eine gemeinsame,
aktuelle Maske bringen.

## „Die mit dieser Lern-Datei verknüpfte Maskendatei hat sich so geändert, dass Daten verloren gingen; die Lern-Datei behält daher ihre eigene Kopie der Maske.“

Sie haben eine Lern-Datei geöffnet, deren verknüpfte `.inf` seit dem letzten Speichern
der Lern-Datei anderswo auf beschädigende Weise geändert wurde. Statt eine Änderung
stillschweigend zu übernehmen, die die Einheiten der Lern-Datei beschädigen würde,
behält die Lern-Datei ihre eigene eingefrorene Kopie und meldet das. Öffnen Sie
**Edit ▸ Mask Editor**, um den Unterschied bewusst zu betrachten und zu lösen.

## Ein Speichern im Mask Editor will „abspalten“, „abbrechen“ oder „erzwingen“

Das ist die
[Warnung vor beschädigenden Änderungen](05-mask-editor.md#speichern-abspalten-oder-direkt-aktualisieren):
Speichern würde eine oder mehrere Lern-Dateien beschädigen, die diese Maske verwenden.
Abspalten, wenn die Lern-Dateien unangetastet bleiben sollen; erzwingen nur, wenn der
Datenverlust sicher gewollt ist; abbrechen, um die Änderung zu überdenken.

## Der Modus-Wechsel-Hinweis zu Beginn einer Sitzung

Beschrieben in [Lernsitzungen](06-learning-sessions.md#die-vier-modi) — er erscheint,
weil Ihre vorhandene Statistik auf der jeweils anderen Seite der Grenze zwischen
Stufenlernen und den übrigen Modi aufgezeichnet wurde. **Neu beginnen** ist die einzige
Option hier, die etwas verwirft, und das wird vor der Bestätigung angezeigt.

## Meine Statistik wird nicht automatisch gespeichert

Automatisches Speichern ist standardmäßig ausgeschaltet — schalten Sie es ein unter
**Optionen ▸ Statistiken ▸ Statistiken automatisch speichern**. Außerdem muss die
Lern-Datei mindestens einmal unter einem echten Pfad gespeichert worden sein: eine
ungespeicherte, nur im Speicher vorhandene Lern-Datei hat keinen Ordner, in dem eine
Statistikdatei angelegt werden könnte. Siehe
[Arbeiten mit Dateien](03-managing-files.md#automatisch-laden-und-automatisch-speichern).

## Meine Statistik ist nach dem Aktualisieren verschwunden

Seit Version 1.2.0 liegen Statistikdateien in einem Ordner namens `statistics` neben
jeder Lern-Datei, und nur dieser Ordner wird gelesen. Dateien, die eine ältere Version
direkt neben die Lern-Datei geschrieben hat, sind noch da und unverändert, aber das
Programm findet sie nicht mehr; die Lern-Datei erscheint deshalb als **noch nicht
gelernt**, und ihre Allzeit-Statistik wirkt leer. Verschieben Sie die `.sta`-Dateien
jeder Lern-Datei mit unveränderten Namen in den Ordner `statistics` daneben und öffnen
Sie die Lern-Datei erneut. Siehe
[Arbeiten mit Dateien](03-managing-files.md#statistik).

## Ich habe im Lerneinheiten- oder Mask Editor etwas durcheinandergebracht und möchte neu anfangen

Drücken Sie `Esc`. Haben Sie seit dem Öffnen des Editors etwas geändert, werden Sie
gefragt, ob das verworfen werden soll; die Bestätigung stellt alles genau so wieder
her, wie es im Moment des Öffnens war — nicht auf die zuletzt gespeicherte Datei, sondern
auf diesen Zwischenstand. Haben Sie bereits **Fertig** gedrückt oder gespeichert, ist
die Änderung endgültig; es gibt kein weiteres Rückgängigmachen.

## Suchverzeichnis existiert nicht

Wird von der [Dateisuche](10-lexicon.md#dateien-durchsuchen) des Lexikons angezeigt,
wenn der gewählte Ordner inzwischen verschoben, umbenannt oder gelöscht wurde. Wählen
Sie den Ordner erneut.

## Nichts hiervon passt zu dem, was ich sehe

Verhält sich ein Bildschirm unerwartet und nichts vom Obigen erklärt es, gehen Sie mit
`Esc` zurück zum Arbeitsbereich und öffnen Sie erneut, was Sie gerade taten — die
meisten Bildschirme bauen ihren Zustand jedes Mal frisch aus der aktuellen Lern-Datei,
Maske und Statistik auf, statt etwas Verborgenes mitzuführen.
