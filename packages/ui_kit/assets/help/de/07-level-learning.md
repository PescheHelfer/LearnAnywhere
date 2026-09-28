# Stufenlernen

Stufenlernen ist eine Hilfestellung je Einheit: jede Einheit startet mit starker
Unterstützung und verliert sie Schritt für Schritt, in vier von 3 bis 0 nummerierten
**Stufen**. Stufe 3 bedeutet die meiste Hilfe, Stufe 0 bedeutet, die Antwort aus dem
Nichts hervorzubringen.

## Die vier Stufen

| Stufe | Was Sie sehen |
|---|---|
| 3 | Die ganze Lösung wird zuerst gezeigt. Die Hauptschaltfläche (`F10`, beschriftet **Verdecken & tippen**) verdeckt sie und macht aus dem Feld eine leere Box, in die dieselbe Antwort aus dem Gedächtnis eingetippt wird, bevor geprüft wird. |
| 2 | Ein **bearbeitbares Gerüst**: jedes zweite Zeichen der Lösung ist bereits eingetragen und fest, die Lücken dazwischen füllen Sie aus. Das **erste** Zeichen jedes Wortes gehört immer Ihnen, sodass selbst eine einzeichige Antwort abgefragt wird. |
| 1 | Nur das erste und letzte Zeichen werden gezeigt, alles dazwischen ist leer. Kurze Wörter fragen dennoch etwas ab: ein zweizeichiges Wort zeigt das erste Zeichen und lässt das letzte offen, ein einzeichiges Wort bleibt leer. |
| 0 | Freies Erinnern — nichts wird gezeigt. Das entspricht dem Antworten ganz ohne Unterstützung durch Stufenlernen. |

Satzzeichen und Leerzeichen werden nie verdeckt, nur Buchstaben und Ziffern — die
eigenen Zeichen eines Wortes tragen die Schwierigkeit, nicht seine Form.

Unterhalb von Stufe 3 behält jedes Wort mindestens eine Lücke, sodass Ihnen nie ein
Feld ohne etwas zu beantworten vorgelegt wird. Eine Folge davon ist bewusst so gewählt:
bei einem dreizeichigen Wort zeigt Stufe 1 zwei Zeichen, Stufe 2 nur eines — bei genau
dieser Länge ist Stufe 1 also geringfügig leichter. Bei einem, zwei, vier und fünf
Zeichen zeigen beide Stufen gleich viele Zeichen, nur an anderen Stellen; ab sechs
Zeichen zeigt Stufe 2 stets mehr.

Die Zeichen, die das Gerüst auf den Bildschirm bringt, zählen als Teil Ihrer Antwort.
Gezeigte Buchstaben sowie die nie verdeckten Satzzeichen und Leerzeichen werden
bewertet, als hätten Sie sie getippt, und sie erscheinen in der Ansicht
**Ihre Antwort**. Ein Feld, das Sie unberührt lassen, wird daher mit seinen gezeigten
Zeichen abgeschickt und nicht als leere Antwort — bei ausgeschalteter Option
**Vollständige Eingabe erforderlich** (siehe
[Wie Antworten bewertet werden](08-answer-evaluation.md)) gilt ein Gerüstfeld also nie
als unbeantwortet.

## Die Leiter hinuntergehen

Eine Einheit wird **befördert** — geht eine Stufe tiefer, was *weniger* Unterstützung
bedeutet —, sobald die Trefferquote der aktuellen Stufe Ihre Beherrschungsschwelle
erreicht. Es gibt **keine automatische Rückstufung**: eine falsche Antwort erhöht nur
den Versuchszähler dieser Stufe, sie schickt eine Einheit nie wieder nach oben. Eine
Einheit verlässt den Übungspool endgültig erst, wenn sie Stufe 0 beherrscht.

Ist [Nur schwierige Einheiten](06-learning-sessions.md#nur-schwierige-einheiten-abfragen)
eingeschaltet, enthält der Pool nur die schwierigen Einheiten im Bereich, jede nur in
der Abfragerichtung, in der sie schwierig ist. Eine Einheit, die Stufe 0 beherrscht,
scheidet trotzdem aus und behält ihre Kennzeichnung.

Sie können das automatische Tempo jederzeit überschreiben mit **Mehr Hilfe** (hebt die
aktuelle Einheit eine Stufe an) und **Weniger Hilfe** (senkt sie eine Stufe), jeweils
begrenzt auf 0 bis 3.

## Wo eine Einheit startet

Die **Einstiegsstufe** auf dem
[Einrichtungsbildschirm](06-learning-sessions.md#eine-sitzung-einrichten) begrenzt, mit
wie viel Unterstützung eine für das Stufenlernen neue Einheit starten darf. Die
Startstufe einer Einheit wird ansonsten aus ihrer bereits in anderen Modi
verzeichneten Trefferquote geschätzt — eine bereits gut bekannte Einheit startet weiter
unten auf der Leiter — und dann durch diese Einstellung begrenzt. **Ohne Begrenzung**
hebt die Obergrenze vollständig auf.

## Stufen benennen

Die vier Stufen haben eigene Namen, die im gesamten Programm statt der reinen
Nummern angezeigt werden. Bearbeiten Sie sie unter
**Optionen ▸ Erweiterte Lernoptionen**, im Feld **Stufennamen** — siehe
[Einstellungen](11-settings.md#lernoptionen). Es gibt zwei Sätze, einen je
Programmsprache, jeweils geordnet von meiste Unterstützung (oben, Stufe 3) bis freies
Erinnern (unten, Stufe 0), mit bis zu 20 Zeichen je Name:

| | Stufe 3 | Stufe 2 | Stufe 1 | Stufe 0 |
|---|---|---|---|---|
| Deutscher Standard | Anfänger | Lerner | Fast geschafft | Meister |
| Englischer Standard | Beginner | Learner | Almost There | Champion |

**Weltraum-Vorlage** setzt einen alternativen deutschen Satz ein (Startrampe, Abflug,
Umlaufbahn, Mondlandung) und sein englisches Gegenstück (Launchpad, Lift-Off, In Orbit,
Moon Landing); **Auf Standard zurücksetzen** stellt die Tabelle oben wieder her.

## Statistik

Das Stufenlernen führt eigene Zähler je Stufe, einsehbar als Stufe-nach-Trefferquote-
Matrix auf dem Bildschirm [Statistik](09-statistics.md#stufenlernen). Eine Einheit, die
Stufe 0 erreicht hat, zählt auch zur Gesamtstatistik (außerhalb des Stufenlernens), sodass
ein späterer Wechsel in den Drill-Modus sie als bereits geübt behandelt statt bei null zu
beginnen.

Die Live-Anzeige **Versuche** einer Stufenlern-Sitzung wird aus genau diesen Zählern je
Stufe gelesen: sie zählt jeden Versuch auf jeder Stufe über die ganze Lern-Datei, in der
Richtung, in der die Sitzung fragt — beide Richtungen nur bei **Beide** — eine Sitzung, in
der Sie die Leiter hinuntergehen, zeigt also Bewegung. Damit liegt sie bewusst höher als
die **Abfrage-Versuche** auf dem Bildschirm [Statistik](09-statistics.md), der nur die
Ergebnisse der Stufe 0 zu sehen bekommt. Beide tragen dieselbe Beschriftung, weil eine
längere nicht auf die Anzeige passt — im Stufenlernen sind **Versuche** also die Arbeit
auf der Leiter.

Für die Stufen-Anzeigen und **Beherrscht** gilt dieselbe Regel wie überall sonst: jede ist
ein Gesamtwert der ganzen Lern-Datei in der Richtung der Sitzung. Eine auf einen
Einheitenbereich eingeschränkte Sitzung zeigt weiterhin, wie sich alle Einheiten der Datei
auf die vier Stufen verteilen und welcher Anteil der ganzen Datei bereits gemeistert ist —
der Bereich entscheidet, was Sie gefragt werden, nicht, was gezählt wird.
