# Statistik

Der Bildschirm **Statistik** (**Statistik ▸ Statistik anzeigen**, `Alt+S` und dann
`A`) liest dieselben Zähler, in die Ihre Sitzungen schreiben. Dasselbe Menü enthält zwei
Befehle für die Kennzeichnungen der geöffneten Lern-Datei, beschrieben unter
[Kennzeichnungen neu berechnen und entfernen](#kennzeichnungen-neu-berechnen-und-entfernen).
Der Bildschirm hat drei Reiter: **Übersicht**, **Einheitenliste** und **Stufenlernen**.

Über den Reitern liegen zwei Zeilen. In der ersten steht der Schalter **Richtung** —
**Kombiniert**, **Abfragerichtung 1** oder **Abfragerichtung 2** — sowie die Umschaltung
**Aktuell** / **Allzeit**, beschrieben unter
[Die zwei Statistiken](#die-zwei-statistiken); im Bereich **Allzeit** kommt eine
Überlauf-Schaltfläche mit drei Punkten dazu, **Allzeit-Aktionen**. In der zweiten stehen
die Dateibefehle, die dem gewählten Bereich folgen: unter **Aktuell** sind das
**Statistik laden... / Statistik speichern / Statistik speichern unter... / Aktuelle
Statistik löschen...**, dieselben Befehle wie im
[Menü Datei](03-managing-files.md#statistik); unter **Allzeit** steht dort nichts als
**Abbruch**, denn keiner dieser Befehle wirkt auf die Statistik, die Sie gerade
ansehen. Was mit diesen Zählern
geschieht, wenn sich die Lern-Datei selbst ändert, steht unter
[Wenn die Lern-Datei anderswo bearbeitet wurde](03-managing-files.md#wenn-die-lern-datei-anderswo-bearbeitet-wurde).

## Die zwei Statistiken

Jede Lern-Datei führt zwei getrennte Aufzeichnungen dessen, was Sie beantwortet haben,
und alle drei Reiter können beide anzeigen. Die Umschaltung **Aktuell** / **Allzeit**
wählt, welche Sie gerade sehen; der Bildschirm öffnet stets mit **Aktuell**.

- **Aktuell** — die Arbeitsstatistik. Aus ihr lernt das Programm: sie bestimmt, welche
  Einheiten in den Übungspool kommen, welche als gemeistert gelten und wo Sie auf der
  Leiter des [Stufenlernens](07-level-learning.md) stehen. Sie ist es, die
  **Statistik laden...** und **Statistik speichern** lesen und schreiben, und sie ist
  das, was eine Sitzungsdatei enthält.
- **Allzeit** — die gesamte Vorgeschichte der Lern-Datei. Sie wächst nur: jede Antwort
  wird ihr in dem Moment hinzugefügt, in dem Sie sie geben, und sonst ändert sie nichts.
  Eine geladene Statistikdatei, eine hinzugefügte Lern-Datei oder das Löschen der
  aktuellen Statistik lassen sie genau so, wie sie war. Sie bestimmt nichts — keinen
  Übungspool, keine Meisterung, keine Position auf der Leiter — und erscheint während
  einer Sitzung nie in den Anzeigen.

Die Allzeit-Statistik wird geführt, ob **Statistiken automatisch speichern**
eingeschaltet ist oder nicht. Diese Option betrifft allein die Sitzungsdateien; die
Allzeit-Statistik wird unabhängig davon bei jeder Antwort geschrieben, in eine eigene
Datei, benannt nach der Lern-Datei — `meinedatei_alltime.sta` neben `meinedatei.vok` —,
die bei der ersten beantworteten Frage entsteht.

Im Bereich **Allzeit** ist die Stufenspalte des Reiters **Stufenlernen** als **letzte**
erreichte Stufe zu lesen, nicht als aktuelle: die Allzeit-Statistik hat keine aktuelle
Position auf der Leiter.

Gelegentlich zeigt der Bildschirm im Bereich **Allzeit** einen stehenden Warnhinweis:
**Diese Allzeit-Statistik wird nicht mehr gespeichert: Die Datei neben der Lern-Datei
gehört zu einer anderen Lern-Datei oder konnte nicht gelesen werden.** Das Programm
überschreibt eine Allzeit-Datei nie, die es nicht lesen konnte; von da an wird diese
Sitzung nur noch auf dem Bildschirm mitgezählt. Die Lern-Datei an ihrem jetzigen Ort
erneut zu öffnen stellt die Aufzeichnung wieder her.

## Eine Statistik löschen

Jede der beiden Aufzeichnungen wird für sich gelöscht, aus ihrem eigenen Bereich
heraus, und keines der beiden Löschen berührt das andere.

- **Aktuelle Statistik löschen...** im Bereich **Aktuell** löscht nach Bestätigung jeden
  verzeichneten Versuch der Arbeitsstatistik. Die Allzeit-Statistik bleibt davon
  unberührt — der Dialog sagt es. Das ist der alltägliche Neuanfang: die Lern-Datei von
  vorn beginnen, ohne ihre Vorgeschichte zu verlieren.
- **Allzeit-Statistik löschen...** im Bereich **Allzeit** löscht den gesamten bisherigen
  Lernverlauf dieser Lern-Datei. Der Befehl liegt mit Absicht außer Sichtweite, denn er
  ist der einzige im Programm, der etwas zerstört, was sich nicht durch Üben
  wiederherstellen lässt. In der Menüleiste kommt er nirgends vor, und auf dem Bildschirm
  steht er auch nicht: Öffnen Sie die Schaltfläche **Allzeit-Aktionen** mit den drei
  Punkten neben der Bereichsumschaltung, dann ist er der einzige Eintrag darin, mit
  Warnzeichen und in der Warnfarbe. Über die Tastatur erreicht `Tab` diese Schaltfläche,
  `Enter` oder `Leertaste` öffnet sie — der Befehl erhält sofort den Fokus —, und `Esc`
  schließt sie ungenutzt wieder.
- Der Befehl fragt zuerst nach. Der Dialog **nennt die Lern-Datei**, deren Verlauf gleich
  verschwindet, damit Sie sicher sein können, welche Aufzeichnung Sie zerstören, und
  fragt, ob Sie das **wirklich** wollen. Der Fokus liegt auf **Abbruch**, `Enter`
  schließt den Dialog also, statt zu bestätigen; nur ein Klick auf **Löschen** führt ihn
  aus.

**Das Löschen der Allzeit-Statistik lässt sich nicht rückgängig machen.** Es gibt keine
Kopie, aus der sie zurückzuholen wäre: die Zahlen stehen in
`<Name der Lern-Datei>_alltime.sta` neben der Lern-Datei, und das Bestätigen nullt genau
diese Datei. Ihre aktuelle Statistik, Ihre Sitzungsdateien und die Lern-Datei selbst
bleiben unangetastet, und spätere Antworten bauen von null an eine neue Vorgeschichte
auf. Wollen Sie die alten Zahlen behalten, kopieren Sie die Datei vorher woandershin.

## Mit der Allzeit-Statistik üben

Die Allzeit-Statistik kann nicht bestimmen, was abgefragt wird — Sie können sie aber
bewusst der Arbeitsstatistik übergeben, wenn ein Durchgang sich nach den Einheiten
richten soll, die Sie über die ganze Lebensdauer der Lern-Datei am häufigsten falsch
hatten.

Wählen Sie **Statistik laden...** und die Datei `_alltime.sta` der Lern-Datei. Weil das
keine gewöhnliche Sitzungsdatei ist, warnt das Programm vorher und benennt, was
geschieht: die Zahlen ersetzen die aktuelle Statistik und bestimmen, welche Einheiten
als Nächstes abgefragt werden, weitere Antworten kommen in eine **neue** Sitzungsdatei,
und die Allzeit-Statistik selbst bleibt unverändert. Lehnen Sie ab, ändert sich gar
nichts.

Nehmen Sie an, wird der Übungspool aus diesen Zahlen neu aufgebaut. Das Programm bietet
nicht an, künftig automatisch in diese Datei zu speichern, und behandelt sie nie als die
Datei, die **Statistik speichern** beschreibt — kein gewöhnliches Speichern kann sie
also erreichen. Die Allzeit-Statistik sammelt derweil im Hintergrund genau so weiter,
wie sie es ohnehin getan hätte.

## Die sieben Bereiche

Die Trefferquote jeder Einheit ordnet sie einem von sieben Bereichen zu, die auf diesem
Bildschirm durchgängig verwendet werden:

| Bereich | Trefferquote |
|---|---|
| Perfekt | 100 % |
| Gut | 75–99 % |
| Mittel | 50–74 % |
| Unsicher | 25–49 % |
| Sehr unsicher | 1–24 % |
| Nie gewusst | 0 % (abgefragt, nie richtig) |
| Noch nicht abgefragt | Keine Versuche verzeichnet |

## Übersicht

Lerneinheiten gesamt, abgefragte Einheiten, Abfrage-Versuche und korrekte Versuche für
den aktuellen Bereich, dann eine Tabelle und ein Balkendiagramm, die jede Einheit nach
Bereich aufschlüsseln — Anzahl, Prozent von allen und Prozent der abgefragten Einheiten.

## Einheitenliste — wonach erneut geübt werden sollte

Eine sortierbare Tabelle jeder Einheit: **Einheit**, **Schwierig**, **Frage**,
**Antwort**, **Abfrage-Versuche**, **Korrekt**. Auf diesem Bildschirm bauen Sie eine
neue Lern-Datei genau aus den Einheiten, die Ihnen Schwierigkeiten bereiten:

1. Liste eingrenzen — auf einen Bereichs-Chip klicken, um ihn ein-/auszuschalten,
   `Strg`+Klick auf einen, um nur diesen anzuzeigen, oder feste Grenzen bei
   **Min %** / **Max %** setzen. **Nur schwierige** einschalten zeigt nur die
   schwierigen Einheiten; es wirkt zusammen mit den Bereichs-Chips und den Grenzen und
   ist ein schlichter Ein/Aus-Schalter — `Strg`+Klick bewirkt dort nichts Besonderes.
2. **Sichtbare auswählen** wählt alles gerade Angezeigte aus, oder einzelne Zeilen
   anklicken. **Auswahl leeren** setzt zurück. Die Schaltflächen wirken nur auf
   ausgewählte Einheiten, die die Liste zeigt — auch auf Zeilen, zu denen Sie erst
   blättern müssten. Eine durch einen Filter verborgene Einheit bleibt angehakt, es
   geschieht ihr aber nichts, bis der Filter sie wieder zeigt.
3. **Ausgewählte Einheiten speichern** schreibt sie als brandneue `.vok`-Lern-Datei —
   die aktuelle Lern-Datei und ihre Statistik bleiben unangetastet; es entsteht nur
   eine neue Datei. Jede Einheit behält dabei ihre Kennzeichnungen; **Nur schwierige**,
   **Sichtbare auswählen**, **Ausgewählte Einheiten speichern** ergibt also eine
   Lern-Datei Ihrer schwierigen Einheiten, die weiterhin gekennzeichnet sind.

Das funktioniert in beiden Bereichen gleich: eine Lern-Datei aus den Sorgenkindern der
ganzen Lebensdauer entsteht genau so wie eine aus denen dieser Woche.

Die Spalte **Schwierig** zeigt, welche Einheiten
[schwierig](06-learning-sessions.md#eine-einheit-als-schwierig-kennzeichnen) sind: eine
Fahne für Ihre manuelle Kennzeichnung, ein Funkeln für die automatische und beide
nebeneinander für beide. Mit der Maus darüber lesen Sie, welche es ist —
**Schwierig (manuelle Kennzeichnung)**, **Schwierig (automatische Kennzeichnung)** oder
**Schwierig (manuelle und automatische Kennzeichnung)**.

Um mehrere Einheiten auf einmal zu kennzeichnen, wählen Sie sie aus und drücken
**Ausgewählte kennzeichnen**: Jede erhält Ihre manuelle Kennzeichnung, eine schon
vorhandene automatische bleibt. **Kennzeichnung entfernen** nimmt jeder ausgewählten
Einheit beide Kennzeichnungen — „nicht schwierig“ heißt nicht schwierig, wie bei `F12`
in einer Sitzung. Die Liste zeigt die Änderung sofort, und die Lern-Datei wird gleich
geschrieben; wie jede Kennzeichnung ist das keine Bearbeitung, das Datum
**Zuletzt bearbeitet** bleibt also, wie es war. Ist nichts ausgewählt, melden beide
**Keine Einheiten ausgewählt.** und ändern nichts.

Ein Hinweis unter der Tabelle zeigt an, wenn die Zahlen **die letzte Stufe aus dem
Stufenlernen einschließen** — auch Ergebnisse von Stufe 0 zählen zu dieser gewöhnlichen
Statistik, eine dort gemeisterte Einheit ist hier also nicht unsichtbar.

## Kennzeichnungen neu berechnen und entfernen

Zwei Befehle im Menü **Statistik** ändern die Kennzeichnungen aller Einheiten der
geöffneten Lern-Datei auf einmal — nur dieser Lern-Datei, wie ihre Namen sagen. Beide
warnen zuerst und nennen dabei die Lern-Datei; mit **Abbruch** ändert sich nichts. Die
Lern-Datei wird gleich geschrieben (eine noch nie gespeicherte nimmt ihre
Kennzeichnungen beim ersten Speichern mit), und wie jede Kennzeichnung ist keiner der
beiden eine Bearbeitung: **Zuletzt bearbeitet** bleibt, wie es war. Solange die
**Eingabe-Maske** geöffnet ist, bitten beide nur darum, sie zuerst zu verlassen — `F10`
behält Ihre Änderungen, `Esc` verwirft sie —, denn das Schreiben der Lern-Datei würde
Ihre unfertigen Änderungen mitspeichern.

- **Automatische Kennzeichnungen der geöffneten Lern-Datei neu berechnen...** misst jede
  Einheit erneut an ihrer Allzeit-Statistik, nach der Regel unter
  [Automatisch gefundene schwierige Einheiten](06-learning-sessions.md#automatisch-gefundene-schwierige-einheiten).
  Eine Einheit, die die Regel erfüllt, trägt danach die automatische Kennzeichnung; eine,
  die sie nicht mehr erfüllt, verliert sie. So verschwinden veraltete automatische
  Kennzeichnungen, denn die Prüfung am Ende einer Sitzung fügt nur hinzu. Manuelle
  Kennzeichnungen bleiben unangetastet. Lern-Dateien aus **Ausgewählte Einheiten
  speichern** beginnen ohne Statistik und können beim Neuberechnen alle automatischen
  Kennzeichnungen verlieren. Eine Meldung nennt danach, wie viele Kennzeichnungen
  hinzukamen und wie viele entfernt wurden. Konnte die Allzeit-Statistik der Lern-Datei
  beim Öffnen nicht gelesen werden, sagt der Befehl das und ändert nichts, statt jede
  Einheit an einer Statistik zu messen, die er nicht sehen konnte. Er misst nach den
  Zahlen unter [Statistik-Optionen](11-settings.md#statistik-optionen) und lässt sich
  nicht wählen, solange die Erkennung dort ausgeschaltet ist.
- **Alle manuellen Kennzeichnungen der geöffneten Lern-Datei entfernen...** entfernt jede
  manuelle Kennzeichnung, damit Sie Ihre eigene Auswahl neu beginnen können. Automatische
  Kennzeichnungen bleiben unangetastet. Eine Meldung nennt, wie viele entfernt wurden.

## Stufenlernen

Eine Matrix mit einer Zeile je Stufe und einer Spalte je Trefferquote-Bereich, dazu
Zeilen- und Spalten-**Gesamt**-Summen, die zeigen, wie sich Ihr Übungspool über beide
Dimensionen zugleich verteilt. Eine Zelle anklicken führt in die Einheiten, die sie
vertritt — dieselbe Einheitenliste wie oben, eingegrenzt auf diese Stufe und diesen
Bereich, auch mit **Nur schwierige** und den Schaltflächen zum Kennzeichnen;
**Zurück** kehrt zur Matrix zurück.

Dieser Reiter enthält erst Daten, sobald im Modus [Stufenlernen](07-level-learning.md)
geübt wurde.
