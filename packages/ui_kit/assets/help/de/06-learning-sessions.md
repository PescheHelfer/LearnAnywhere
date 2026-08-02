# Lernsitzungen

Eine Sitzung besteht darin, dass Sie nacheinander Karten aus der geladenen Lern-Datei
gestellt bekommen. Alles darüber, wie eine Sitzung Karten auswählt und darstellt,
beginnt auf dem Bildschirm **Übung einrichten** (**Lern ▸ Übung einrichten**, `Alt+L`
dann `E`).

## Eine Sitzung einrichten

| Einstellung | Wirkung |
|---|---|
| **Abfragerichtung** | In welche der beiden Richtungen der Maske gefragt wird, oder **Beide**, um sie zu mischen |
| **Modus** | **Stufenlernen**, **Drill-Modus**, **Endlos-Modus** oder **Einmal durchgehen** — siehe unten |
| **Einstiegsstufe** | Nur Stufenlernen — begrenzt, mit wie viel Unterstützung eine neu eingestufte Einheit starten darf; siehe [Stufenlernen](07-level-learning.md) |
| **Einheiten mischen** | In zufälliger statt in Dateireihenfolge fragen |
| **Beherrschungsschwelle (%)** | Nur Drill-Modus — eine Einheit gilt als gemeistert, sobald ihre Trefferquote diesen Wert erreicht |
| **Mit Eingabe der Antwort** | Ausgeschaltet warten Karten darauf, dass Sie sich selbst bewerten, statt zu tippen; beim Stufenlernen ausgeblendet, da dort immer getippt wird |
| **Erste Einheit** / **Letzte Einheit** | Begrenzt die Sitzung auf einen Bereich der Lern-Datei; ein geleertes Feld erweitert ihn bis zur ersten bzw. letzten Einheit. **Alle Einheiten verwenden ({count})** setzt beide auf einmal zurück |

**Sitzung starten** beginnt die Sitzung. Läuft bereits eine Sitzung, heißt diese
Schaltfläche stattdessen **Fortsetzen** und führt direkt zurück hinein.

## Die vier Modi

- **Stufenlernen** führt jede Einheit eine Leiter aus abnehmender Unterstützung
  hinunter, bis Sie sie aus dem Nichts hervorbringen können. Dieser Modus hat ein
  eigenes Kapitel: [Stufenlernen](07-level-learning.md).
- **Drill-Modus** hält einen Pool aus jeder noch nicht **gemeisterten** Einheit —
  Trefferquote unterhalb der Beherrschungsschwelle — und fragt aus diesem Pool, bis er
  leer ist. Der Pool wird jedes Mal neu aus Ihrer Statistik berechnet; ein Anheben der
  Schwelle oder ein Erweitern des Einheitenbereichs bringt Einheiten also zurück, ohne
  bereits Verzeichnetes zu verlieren. Sie können mittendrin aufhören und später
  fortsetzen, auch nach einem Neustart des Programms.
- **Endlos-Modus** wählt zufällig aus dem gesamten Bereich, solange Sie weitermachen;
  nichts wird je aus dem Pool entfernt.
- **Einmal durchgehen** fragt jede Einheit im Bereich genau einmal und ist dann fertig.

Stammt die vorhandene Statistik aus einem anderen Modus — genauer: von der jeweils
anderen Seite der Grenze zwischen Stufenlernen und den übrigen Modi —, fragt der
Sitzungsstart zuerst: **Statistik behalten** und unverändert weitermachen,
**Für Stufen verwenden** (jede Einheit anhand ihrer bisherigen Trefferquote auf eine
Startstufe einordnen) oder **Neu beginnen** (löscht alles, einschließlich des
Fortschritts im Stufenlernen — das lässt sich nicht rückgängig machen).

## Während einer Sitzung

Die Kopfzeile zeigt **"Einheit {index}/{total}"**. Darunter:

- **Frage** — die Frage-Felder für diese Richtung.
- Ein Eingabefeld für **Ihre Antwort**, falls **Mit Eingabe der Antwort** eingeschaltet
  ist; andernfalls wartet die Karte darauf, dass Sie sich selbst bewerten.
- **Bemerkungen**, falls die Maske Felder mit dieser Rolle hat.

Mit `F3` oder `Enter` **prüfen**. Was dann passiert, hängt davon ab, ob Ihre Antwort
gestimmt hat — vollständig erklärt in
[Wie Antworten bewertet werden](08-answer-evaluation.md) — aber in jedem Fall geht es
danach entweder automatisch weiter, oder Sie wählen über eine Reihe von Schaltflächen
(`F5`/`F6`/`F7`), wie der Versuch bewertet werden soll.

`F10` **zeigt** die Karte, ohne dass Sie antworten, falls Sie lieber nachsehen als raten
wollen. `F9` wechselt durch, was der Antwortbereich zeigt: **Korrektur** (Ihre Antwort
mit gegen die Lösung hervorgehobenen Unterschieden) → **Lösung** → **Ihre Antwort**.

Eine Live-Anzeige verfolgt **Versuche**, **Beherrscht**, **Übrig**, **Korrekt**, die
Trefferquote der aktuellen Einheit sowie — falls in den
[Einstellungen](11-settings.md#lernoptionen) eingeschaltet — die verstrichene **Zeit**.

`Esc` beendet die Sitzung und kehrt zur Einrichtung zurück. Im Drill-Modus geht dabei
nichts verloren: der Pool wird beim nächsten Start aus der Statistik neu aufgebaut.

## Abschluss

Sowohl Einmal durchgehen als auch der Drill-Modus enden, wenn nichts mehr zu fragen
übrig ist — der Drill-Modus, wenn alles gemeistert ist, Einmal durchgehen nach der
letzten Einheit. In beiden Fällen können Sie **Sitzung erweitern** drücken, um über das
Ende hinaus weiterzumachen, statt dort aufzuhören.
