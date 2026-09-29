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
| **Nur schwierige Einheiten ({count})** | Nur die schwierigen Einheiten fragen, jede nur in der Abfragerichtung, in der sie schwierig ist, in jedem Modus; die Zahl zeigt, wie viele es sind — siehe [Nur schwierige Einheiten abfragen](#nur-schwierige-einheiten-abfragen) |
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
(`F5`/`F6`/`F7`), wie der Versuch bewertet werden soll. Diese Reihe steht direkt neben
**Weiter** und **Abbruch**, sodass beide Gruppen in Reichweite bleiben. Bei einem
schmalen Fenster rutschen die Bewertungsschaltflächen in eine eigene Zeile, statt
abgeschnitten zu werden.

Innerhalb jeder Gruppe stehen die Schaltflächen in der Reihenfolge ihrer Tasten, und
**Abbruch** steht zuletzt in seiner Gruppe: **Weiter** (`F3`), **Vorlesen** (`F4`), der
Umschalter der Antwortansicht (`F9`) und **Abbruch** (`Esc`); dann die
Bewertungsschaltflächen (`F5`/`F6`/`F7`); dann **Schwierig** (`F12`) für sich allein.
Vor dem Anzeigen der Antwort liest sich die Reihe genauso: **Weniger Hilfe** und **Mehr
Hilfe** beim [Stufenlernen](07-level-learning.md), **Vorlesen**, wo es etwas vorzulesen
gibt, **Prüfen**, **Anzeigen** oder **Verdecken & tippen** (`F10`) und **Abbruch** in einer
Gruppe, dann **Schwierig**. Eine Gruppe wird nie auf zwei Zeilen verteilt.

`F10` **zeigt** die Karte, ohne dass Sie antworten, falls Sie lieber nachsehen als raten
wollen. `F9` wechselt durch, was der Antwortbereich zeigt: **Korrektur** (Ihre Antwort
mit gegen die Lösung hervorgehobenen Unterschieden) → **Lösung** → **Ihre Antwort**.

Ein kleines Lautsprecher-Symbol neben einem Feld liest dieses Feld vor. Es erscheint
überall dort, wo die Maske das Vorlesen des Feldes erlaubt und dessen Wert auf dem
Bildschirm steht — die Frage also sofort, die Antwort nach dem Prüfen. Siehe
[Sprachausgabe](15-speech.md#felder-vorlesen-lassen).

Ist das **automatische Vorlesen** eingeschaltet, liest sich die Antwort bei jedem
Aufdecken selbst vor, richtig oder falsch, und `F4` liest sie erneut vor, wann immer Sie
wollen — siehe
[Die Antwort automatisch vorlesen](15-speech.md#die-antwort-automatisch-vorlesen).
Die Schaltfläche **Vorlesen** tut dasselbe mit der Maus. Sie ist genau dann da, wenn
`F4` etwas vorlesen würde: sobald die Antwort auf dem Bildschirm steht, falls die Maske
das Vorlesen eines Antwortfeldes erlaubt und Ihr Computer überhaupt sprechen kann.

Eine Live-Anzeige verfolgt **Versuche**, **Beherrscht**, **Übrig**, **Korrekt**, **Einheit
korrekt** — die Zahl der aktuellen Einheit — sowie, falls in den
[Einstellungen](11-settings.md#lernoptionen) eingeschaltet, die verstrichene **Zeit**.

**Versuche**, **Beherrscht**, **Übrig** und **Korrekt** beschreiben jeweils **die ganze
Lern-Datei in der Richtung, in der diese Sitzung fragt** — nicht die Sitzung und nicht den
Einheitenbereich. (Die beiden folgenden Anzeigen sind bewusst enger: **Einheit korrekt**
gilt nur dieser einen Einheit, und **Zeit** ist die Uhr dieser Sitzung.) Ein
eingeschränkter Bereich verkleinert, was Sie gefragt werden, nie das, was gezählt wird; die
vier nebeneinanderstehenden Zahlen beschreiben also immer dieselbe Menge: eine Sitzung über
die Einheiten 5–10 einer Datei mit 200 Einheiten weist **Beherrscht** und **Übrig**
weiterhin von allen 200 aus (**Übrig** zeigt dann eine zweite Zahl, siehe unten). Ist
unter **Abfragerichtung** eine der beiden Richtungen der Maske gewählt, zählen sie nur
diese; bei **Beide** jede Einheit in beiden Richtungen.

**Übrig** zeigt eine zweite Zahl, wenn die Sitzung weniger als die ganze Lern-Datei
abfragt — einen Einheitenbereich oder
[Nur schwierige Einheiten](#nur-schwierige-einheiten-abfragen): **Übrig: 120 (4)**
heißt, 120 Fragen der Lern-Datei sind noch nicht beherrscht, und 4 davon liegen in dem,
was diese Sitzung abfragt. Auf diese zweite Zahl kommt es an: Der Drill-Modus endet
genau dann mit „alles beherrscht“, wenn sie 0 erreicht. Ob sie erscheint, wird beim Start der
Sitzung entschieden; die Anzeige behält ihre Form also, bis Sie die Sitzung verlassen.
Beide Zahlen zählen Fragen, bei **Beide** zählt eine Einheit also einmal je Richtung. Das
Stufenlernen hat kein **Übrig**.

Mit der Maus über einer dieser Anzeigen lesen Sie, was sie zählt.

**Versuche** und **Korrekt** werden aus der Statistik der Lern-Datei gelesen — es sind
keine Zähler für die aktuelle Sitzung. Sie beginnen mit dem, was bereits verzeichnet ist,
behalten ihren Wert, wenn Sie eine Sitzung verlassen und eine neue starten, und sind auch
nach dem Schließen und erneuten Öffnen des Programms noch da. Damit sind es dieselben
Zahlen, die der Bildschirm [Statistik](09-statistics.md) als **Abfrage-Versuche** und
**Korrekte Versuche** ausweist, sofern dessen Schalter **Ansicht** zur Sitzung passt:
**Kombiniert** bei **Beide**, sonst **Abfragerichtung 1** bzw. **Abfragerichtung 2**. (Der
Bildschirm öffnet sich auf **Abfragerichtung 1**, zum Vergleichen also umschalten.) Es
gibt somit nur einen Satz Zahlen, dem Sie trauen müssen. Beim Laden einer anderen
Lern-Datei erscheinen deren eigene Gesamtwerte und nichts aus der vorherigen. Ein mit
**Nicht zählen** bewerteter Versuch verzeichnet nichts und bewegt sie deshalb ebenfalls
nicht.

`Esc` beendet die Sitzung und kehrt zur Einrichtung zurück. Im Drill-Modus geht dabei
nichts verloren: der Pool wird beim nächsten Start aus der Statistik neu aufgebaut.

## Eine Einheit als schwierig kennzeichnen

Macht Ihnen eine Einheit Mühe, halten Sie das in dem Moment fest, in dem Sie es merken:
Drücken Sie `F12` oder klicken Sie auf die Schaltfläche **Schwierig** neben den übrigen
Schaltflächen der Sitzung. Das geht beim Antworten ebenso wie nach dem Anzeigen der
Antwort, und es bewertet nichts, deckt nichts auf und geht nicht weiter — die Karte
bleibt genau, wo sie war.

Eine Einheit ist **in einer Abfragerichtung** schwierig: Ein Wort kann schwer
hervorzubringen und leicht zu erkennen sein. `F12` und die Schaltfläche wirken immer auf
die Richtung, in der Sie gerade gefragt werden, und lassen die andere Richtung genau, wie
sie war.

Ist die Einheit in der gefragten Richtung schwierig, zeigt ihre Kopfzeile ein Abzeichen.
Über die andere Richtung sagt es nichts. Es zeigt, wer sie gekennzeichnet hat — eine
Fahne für Ihre manuelle Kennzeichnung, ein Funkeln für die automatische oder beide —,
gefolgt von **Schwierig**. Mit der Maus darüber lesen Sie, welche es ist:

- **Manuelle Kennzeichnung** — Sie selbst.
- **Automatische Kennzeichnung** — das Programm, anhand der Allzeit-Statistik der
  Einheit (siehe
  [Automatisch gefundene schwierige Einheiten](#automatisch-gefundene-schwierige-einheiten)).
- **Manuelle und automatische Kennzeichnung** — beide.

Die Schaltfläche **Schwierig** ist gefüllt, solange die Einheit in der gefragten
Richtung schwierig ist. `F12` (oder die Schaltfläche) hebt ihre Schwierigkeit dann in
dieser Richtung ganz auf — die automatische Kennzeichnung ebenso wie Ihre eigene —, denn
„nicht schwierig“ heißt nicht schwierig. Ist die Einheit in dieser Richtung nicht
schwierig, setzt es dort Ihre manuelle Kennzeichnung.

Die Kennzeichnung gehört zur Einheit und steht in der Lern-Datei; das Löschen einer der
beiden Statistiken entfernt sie also nicht. Sie wird **sofort** in die Datei
geschrieben, nicht erst beim nächsten Speichern, damit ein vergessenes Speichern oder
ein Absturz Ihr Urteil nicht verliert. Daraus folgt zweierlei:

- Eine Kennzeichnung ist keine Bearbeitung: das Datum **Zuletzt bearbeitet** im
  Arbeitsbereich ändert sich nicht.
- Geschrieben wird die ganze Lern-Datei. Haben Sie in derselben Sitzung in der
  **Eingabe-Maske** etwas geändert, wird diese Änderung mit der Kennzeichnung
  gespeichert — und sie verschiebt **Zuletzt bearbeitet** sehr wohl.

Lässt sich die Datei nicht schreiben — sie ist schreibgeschützt, oder ihr Ordner ist
verschwunden —, nennt eine Meldung die Datei, und die Sitzung geht weiter. Die
Kennzeichnung ist dann nur im Speicher: Wählen Sie **Datei ▸ Lerneinheiten speichern**,
sobald die Datei wieder beschreibbar ist, sonst geht die Änderung beim Schließen des
Programms verloren.

Ältere Versionen von Learn Anywhere öffnen eine Lern-Datei mit Kennzeichnungen, verwerfen
aber alle Kennzeichnungen, wenn sie sie speichern. Aktualisieren Sie jeden Computer, auf
dem Sie Ihre Lern-Dateien bearbeiten.

## Automatisch gefundene schwierige Einheiten

Immer wenn eine Lernsitzung endet — alles gemeistert, Sie brechen ab, oder Sie schließen
das Programm —, sucht Learn Anywhere in der Lern-Datei nach Einheiten, die Sie immer
wieder falsch beantworten, und gibt ihnen die automatische Kennzeichnung. Die Regel
lautet: Eine Einheit ist schwierig, wenn Sie sie **mindestens zweimal** und **in
mindestens einem Drittel der Fälle** falsch beantwortet haben, und — falls Sie sie noch
nie richtig beantwortet haben — erst nach **mindestens sechs Versuchen**. Das sind die
Standardwerte: Alle drei Zahlen lassen sich ändern und die Prüfung lässt sich ausschalten,
unter [Schwierige Einheiten](11-settings.md#schwierige-einheiten).

- Beurteilt wird jede Einheit allein nach ihrer eigenen **Allzeit-Statistik**, nie danach,
  wie es im Rest der Lern-Datei läuft. Das Löschen der aktuellen Statistik macht die
  Suche also nicht blind, und eine Lern-Datei, die Sie nie geübt haben, erhält keine
  Kennzeichnungen.
- Jede Abfragerichtung wird nach ihrer eigenen Statistik beurteilt, und die
  automatische Kennzeichnung wird nur in der Richtung gesetzt, die die Regel erfüllt;
  eine Einheit, die in beiden Richtungen schwierig ist, erhält sie in beiden.
- Antworten im Stufenlernen zählen nur, wenn sie auf Stufe 0 gegeben wurden, ganz ohne
  Hilfe; Antworten mit Unterstützung auf den anderen Stufen zählen nicht.
- Es kommen nur Kennzeichnungen hinzu. Eine Einheit, die Sie inzwischen können, behält
  ihre automatische Kennzeichnung, bis Sie sie entfernen — mit `F12`, mit
  **Kennzeichnung entfernen** in der
  [Einheitenliste](09-statistics.md#einheitenliste--wonach-erneut-gebt-werden-sollte)
  oder für die ganze Lern-Datei mit
  [Automatische Kennzeichnungen neu berechnen...](09-statistics.md#kennzeichnungen-neu-berechnen-und-entfernen).
- Die Lern-Datei wird nur geschrieben, wenn eine Kennzeichnung hinzukam, und wie das
  Kennzeichnen ist das keine Bearbeitung: **Zuletzt bearbeitet** ändert sich nicht. Lässt
  sich die Datei nicht schreiben, nennt eine Meldung sie; Ihre Statistik ist davon nicht
  betroffen.

## Nur schwierige Einheiten abfragen

Schalten Sie auf dem Einrichtungsbildschirm **Nur schwierige Einheiten** ein, um nur die
schwierigen Einheiten gefragt zu werden — jene mit einer der beiden Kennzeichnungen,
Ihrer eigenen oder der des Programms. Jede Einheit wird nur in der Abfragerichtung
gefragt, in der sie schwierig ist: Bei **Beide** wird eine Einheit, die nur in einer
Richtung schwierig ist, nie in der leichten Richtung gefragt. Das wirkt in jedem Modus:
Es schränkt ein, was der Modus fragen würde, innerhalb des Einheitenbereichs. Die
Kennzeichnungen überdauern die Statistik; Sie können also die Statistik für einen
frischen Durchgang löschen und dann in derselben Lern-Datei nur die Wörter üben, die
Ihnen Mühe gemacht haben.

- Eine gemeisterte Einheit scheidet wie gewohnt aus der Sitzung aus, behält aber ihre
  Kennzeichnung. Wenn Sie sicher sind, dass Sie sie können, entfernen Sie sie mit `F12`.
- Eine Einheit, deren Kennzeichnung Sie während der Sitzung mit `F12` entfernen, wird
  nicht mehr gefragt, und entfernen Sie die letzte, endet die Sitzung mit „Keine
  schwierigen Einheiten mehr abzufragen.“, statt zu behaupten, Sie beherrschten alle.
- **Versuche**, **Beherrscht** und **Korrekt** beschreiben weiterhin die ganze Lern-Datei,
  genau wie bei einem eingeschränkten Einheitenbereich; **Übrig** zeigt die Zahl der
  Lern-Datei und dahinter, was dieser Sitzung noch bleibt, etwa **Übrig: 120 (4)**.
- Ist keine Einheit im Bereich in der gewählten Abfragerichtung schwierig, sagt die
  Einrichtung das, und **Sitzung starten** bleibt gesperrt, bis Sie die Option
  ausschalten, den Bereich erweitern, eine andere Richtung wählen oder eine Einheit
  kennzeichnen.
- Die Option zeigt, wie groß die Abfrage wird, in Einheiten: **(3)**, wenn der Bereich
  jede in der gewählten Abfragerichtung schwierige Einheit enthält (mit **Alle
  Einheiten verwenden ({count})** immer), **(1/3)**, wenn er einige auslässt — eine von den drei
  schwierigen Einheiten der Lern-Datei. Bei **Beide** zählt eine Einheit, die in einer der beiden Richtungen
  schwierig ist, einmal. Die Zahl folgt **Erste Einheit**, **Letzte Einheit** und der
  Abfragerichtung, während Sie sie ändern, und ihr Tooltip erklärt sie.
- Die Option wird wie die übrigen Einstellungen der Einrichtung gespeichert.

## Abschluss

Sowohl Einmal durchgehen als auch der Drill-Modus enden, wenn nichts mehr zu fragen
übrig ist — der Drill-Modus, wenn alles gemeistert ist, Einmal durchgehen nach der
letzten Einheit. Eine Sitzung mit
[Nur schwierige Einheiten](#nur-schwierige-einheiten-abfragen), der die Einheiten
ausgehen, weil Sie der letzten schwierigen die Kennzeichnung entfernt haben, meldet
stattdessen „Keine schwierigen Einheiten mehr abzufragen.“ In beiden Fällen können Sie
**Sitzung erweitern** drücken, um über das
Ende hinaus weiterzumachen, statt dort aufzuhören.
