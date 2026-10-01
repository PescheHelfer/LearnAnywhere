# Die Android-Begleit-App

Zu Learn Anywhere gehört eine zweite, deutlich kleinere App für Android-Telefone. Sie ist
eine **Begleit-App** und keine Portierung: Sie gibt es, damit Sie Lern-Dateien, die Sie am
Computer erstellt haben, auch unterwegs weiterüben können. Alles, was Material anlegt oder
ändert — die Bearbeitung der Lerneinheiten, der Mask Editor, das Lexikon — bleibt auf dem
Desktop.

Die Telefon-App enthält dieses Kapitel des Handbuchs, und nur dieses. Der Rest des
Handbuchs beschreibt Menüs, Funktionstasten und Editoren, die es auf einem Telefon nicht
gibt.

## Was die Begleit-App kann und was nicht

Die Begleit-App ist **nur lesend** und arbeitet **ohne Tippen**. Sie zeigt Ihnen eine
Karte, Sie entscheiden im Kopf, ob Sie es wussten, und teilen der App mit, was der Fall
war. Es wird nichts eingegeben.

Sie bietet:

- Ihre importierten Lern-Dateien in einer Bibliothek auf dem Telefon.
- Üben im **Drill-Modus**, im **Endlos-Modus** und **Einmal durchgehen**.
- Lautsprecher-Symbole und, wenn Sie es einschalten, die automatisch vorgelesene Antwort
  — siehe [Sprachausgabe](#sprachausgabe) unten.
- Statistik je Lern-Datei, gespeichert nach jeder bewerteten Karte.
- Das Abzeichen an Einheiten, die Sie am Desktop als schwierig gekennzeichnet haben, und
  Üben nur dieser Einheiten — siehe [Schwierige Einheiten](#schwierige-einheiten).
- Einstellungen für Darstellung und Sprache sowie die beiden unten beschriebenen
  Schutzregeln.

Bewusst nicht enthalten sind:

- **Tippen.** Es wird nie eine Antwort eingegeben, also wird auch nichts verglichen oder
  bewertet.
- **Stufenlernen.** Dieser Modus fragt eine getippte Antwort mit immer weniger
  Hilfestellung ab und kann ohne Tippen nicht existieren.
- **Bearbeiten.** Keine Bearbeitung von Lerneinheiten, kein Mask Editor, kein Lexikon.
  Lern-Dateien entstehen am Desktop.
- **Schwierige Einheiten kennzeichnen.** Das Telefon zeigt die am Desktop gesetzten
  Kennzeichnungen, setzt, entfernt oder erkennt aber selbst nie eine und hat keine
  Einstellungen dafür.
- **Abgleich.** Das Telefon sieht nie die Statistik des Computers und der Computer nie
  die des Telefons. Siehe "Zwei Geräte, zwei Statistiken" weiter unten.

## Lern-Dateien aufs Telefon bringen

Der Startbildschirm der App ist die Bibliothek mit dem Titel **Bibliothek**. Beim ersten
Öffnen steht dort **Noch keine Lern-Dateien**.

Tippen Sie oben auf **Lern-Dateien importieren** und wählen Sie mit Androids eigener
Dateiauswahl eine oder mehrere `.vok`-Dateien aus; mehrere auf einmal sind möglich. Die
Dateien werden in den eigenen Speicher der App **kopiert**. Die Originale — auf der
SD-Karte, im Download-Ordner, in einer Cloud-App — bleiben unangetastet, und wenn Sie sie
später löschen, ändert das an den Kopien nichts.

Zwei Dinge sind dabei zu wissen:

- **Keine Maskendatei.** Lern-Dateien auf Android verwenden nie eine separate
  `.inf`-Datei; die Maske steckt in der `.vok`-Datei selbst. Wenn Sie eine alte
  Lern-Datei haben, deren Maske in einer eigenen Datei liegt, öffnen und speichern Sie
  sie zuvor einmal am Desktop.
- **Die Bibliothek ist flach.** Wie Ihre Lern-Dateien am Computer auch in Ordnern liegen
  mögen — auf dem Telefon sind sie eine einzige Liste, benannt nach dem Dateinamen.
  Androids Dateiauswahl übergibt der App nur einen Anzeigenamen und keinen Ordnerpfad,
  die Struktur lässt sich also nicht rekonstruieren.

Jeder Eintrag trägt den Dateinamen der Lern-Datei als Titel, ohne die Endung `.vok`.
Darunter steht der Name der Maske, aus der die Lern-Datei erstellt wurde; Lern-Dateien
aus derselben Maske erkennen Sie also an ihren Dateinamen. Die Anzahl der Einheiten
steht am rechten Rand der Zeile. Überall sonst — in **Übung einrichten** und in
der Lernsitzung — wird eine Lern-Datei allein mit ihrem Dateinamen benannt. Ein Tippen
öffnet den Eintrag; das Papierkorb-Symbol bietet **Löschen** an, wodurch die Lern-Datei
**und ihre Statistik von diesem Gerät** entfernt werden.

**Die Liste ist danach geordnet, wann Sie eine Lern-Datei zuletzt geübt haben, die
zuletzt geübte zuoberst**, damit die Datei, an der Sie gerade arbeiten, oben steht und
das Weitermachen ein einziges Antippen kostet. Noch nie geübte Lern-Dateien stehen ganz
oben — eine soeben importierte Datei ist die, für die Sie die App geöffnet haben.
Innerhalb beider Gruppen wird nach Namen geordnet, sodass sich die Liste zwischen zwei
Besuchen nicht umsortiert, wenn sich nichts geändert hat. Es gibt nichts einzustellen,
und es werden keine Datumsangaben angezeigt: die Reihenfolge selbst ist die Information.

**Importieren Sie eine Lern-Datei erneut, die es schon gibt, wird sie ersetzt und ihre
Statistik bleibt erhalten.** Das ist der normale Weg, eine am Computer bearbeitete
Lern-Datei nachzuziehen: erneut exportieren, erneut importieren, und Ihre Trefferquoten
überleben. Die App ordnet die alte Statistik den neuen Einheiten anhand ihres Frage- und
Lösungstextes zu, verschobene Einheiten behalten ihre Vorgeschichte also. Einheiten, deren
Frage- oder Lösungstext Sie tatsächlich geändert haben, beginnen wieder bei null, weil
ihre Statistik die Karte vor Ihnen nicht mehr beschreibt. Eine geänderte Bemerkung ändert
nichts.

## Übung einrichten

Beim Öffnen einer Lern-Datei erscheint **Übung einrichten** — dieselben Einstellungen wie
auf dem Einrichtungsbildschirm des Desktops, ohne alles, was nur beim Tippen einen Sinn
ergibt:

| Einstellung | Wirkung |
|---|---|
| **Abfragerichtung** | In welche Richtung abgefragt wird. Die beiden Namen stammen aus der Maske der Lern-Datei, oder **Beide**. |
| **Modus** | **Drill-Modus**, **Endlos-Modus** oder **Einmal durchgehen**. |
| **Beherrschungsschwelle (%)** | Nur im Drill-Modus: die Trefferquote, die eine Einheit erreichen muss, um aus dem Pool zu fallen. |
| **Einheiten mischen** | Eingeschaltet kommen die Karten in jedem Durchgang neu gemischt, ausgeschaltet in der Reihenfolge der Datei. |
| **Nur schwierige Einheiten ({count})** | Nur die als schwierig gekennzeichneten Einheiten fragen, jede nur in der Abfragerichtung, in der sie schwierig ist; die Zahl zeigt, wie viele es sind — siehe [Schwierige Einheiten](#schwierige-einheiten). |
| **Erste Einheit** / **Letzte Einheit** | Nur einen Teil der Lern-Datei üben. |

Ihre Auswahl wird gemerkt — außer dem Einheitenbereich, der beim Öffnen einer Lern-Datei
jedes Mal zurückgesetzt wird, weil ein Bereich, der zu einer Datei passt, für die nächste
bedeutungslos ist.

**Sitzung starten** beginnt die Übung. Eine Option für getippte Antworten gibt es hier
nicht: auf dem Telefon ist sie immer aus.

## Eine Karte, zwei Antippen

Jede Karte braucht genau zwei Antippen.

**Erstes Antippen.** Die Karte zeigt die **Frage**, oben am Bildschirm verankert und über
die volle Breite, und eine Schaltfläche, **Antwort zeigen**. Eine kurze und eine lange
Frage lassen die Karte gleich aussehen; eine Frage, die nicht auf die Karte passt,
schrumpft zunächst und lässt sich dann scrollen, sodass nichts abgeschnitten wird.

Direkt unter der Karte, an ihrer Unterkante, sagen zwei Zeilen, wonach sie fragt.

**Kategorie** benennt die Kategorie der Einheit — die Art des Eintrags. So
erkennen Sie, ob es sich um eine Kategorie handelt, die der Autor der Lern-Datei
"Synonyme" genannt hat und bei der die Reihenfolge Ihrer Antworten keine Rolle spielt,
oder um eine zweizeilige Kategorie, bei der sie es tut.

**Erwartete Lösungsfelder:** listet auf, woraus die Antwort besteht, mit
einem kleinen abgerundeten Kästchen je Feld. Bei einer einfachen Kategorie ist das ein
einziges Kästchen; bei einer Verb-Kategorie können es drei sein, sodass Sie Infinitiv,
Partizip *und* Hilfsverb vorbereiten, statt beim ersten aufzuhören. Jeder Feldname steht
in einem eigenen Kästchen, damit ein Name mit einem Leerzeichen als ein Feld und nicht
als zwei gelesen wird. Die Liste beschreibt die Richtung, die Sie gerade üben, und
Felder, die der Autor der Lern-Datei ausgeblendet hat, fehlen darin. Bei einer Kategorie,
deren Antwort gar keine Felder hat, entfällt die Zeile — die Zeile mit der Kategorie
bleibt aber stehen.

Sobald Sie die Lösung anzeigen, verschwinden beide: dann benennt die Lösung selbst jedes
Feld neben seinem Wert.

Da diese beiden Zeilen der Karte Platz wegnehmen, kann eine Frage bei einer Kategorie mit
vielen Feldern eine Stufe kleiner gesetzt sein, als sie es sonst wäre.

**Zweites Antippen.** Die Karte zeigt nun die **Lösung** und etwaige **Bemerkungen**, mit
einem Umschalter **Frage** / **Lösung** darüber und drei Bewertungsschaltflächen
darunter:

- **Gewusst** — zählt als korrekter Versuch.
- **Nicht gewusst** — zählt als falscher Versuch.
- **Nicht zählen** — zeigt Ihnen die Karte, ohne etwas aufzuzeichnen. Nützlich, wenn Sie
  gestört wurden oder etwas nachschlagen wollen, ohne die Zahlen zu verfälschen.

Der Umschalter **Frage** / **Lösung** lässt Sie die Frage so oft ansehen, wie Sie
möchten, bevor Sie die Karte bewerten — die drei Bewertungsschaltflächen bleiben dabei an
ihrem Platz und in beiden Stellungen bedienbar.

Was Sie auch antippen: es bewertet die Karte und geht zugleich zur nächsten weiter, ein
eigener Schritt zum Weiterblättern entfällt. Das entspricht dem Desktop, wo Sie die
Lösung anzeigen und dann eine von drei Tasten drücken. Die nächste Karte beginnt immer
wieder bei der Frage, unabhängig davon, wie der Umschalter bei der vorigen Karte stand.

Über der Karte beschreiben eine Fortschrittsleiste und zwei Zahlen — **Beherrscht** und
**Korrekt** — **die ganze Lern-Datei in der Richtung, in der diese Sitzung
fragt**, nicht den laufenden Durchgang und nicht den gewählten Einheitenbereich: ein
eingeschränkter Bereich verkleinert, was Sie gefragt werden, nie das, was hier gezählt
wird, sodass die Leiste beim Einschränken des Bereichs nicht springt. **Beherrscht** ist
ein Anteil an der ganzen Lern-Datei; was übrig bleibt, ist also der Rest davon — und die
Fortschrittsleiste darüber zeigt dasselbe als Balken. Der Desktop, der ein breiteres
Fenster zu füllen hat, weist diesen Rest als eigene Zahl aus. **Korrekt** —
korrekte Versuche von allen Versuchen, mit einer Prozentzahl — zählt nur diese Richtung.
Diese Zahlen stimmen mit den Live-Anzeigen des Desktops für dieselbe Datei und Richtung
überein; die Statistik des Telefons zeigt immer die kombinierte Zahl, da sie keine eigene
Richtungsansicht hat, und stimmt deshalb nur genau überein, wenn Sie **Beide** Richtungen
üben.

Fragt die Sitzung weniger als die ganze Lern-Datei — einen Einheitenbereich oder
[Nur schwierige Einheiten](#schwierige-einheiten) —, kommt eine dritte Zahl dazu:
**Übrig: 120 (4)** heißt, dass 120 Fragen der Lern-Datei noch nicht beherrscht sind und 4
davon in dem liegen, was diese Sitzung abfragt. Auf diese zweite Zahl kommt es an: Der
Drill-Modus endet genau dann mit allem beherrscht, wenn sie 0 erreicht. Beide Zahlen
zählen Fragen, bei **Beide** zählt eine Einheit also einmal je Richtung. Halten Sie eine
der Zahlen gedrückt, um nachzulesen, was sie zählt.

Zwischen diesen Zahlen zur ganzen Lern-Datei und der Karte steht die Zeile zur Einheit
selbst: **Einheit x/y**, dann **Einheit korrekt** — die Versuche, die für *diese* Einheit
in der gefragten Richtung aufgezeichnet sind, als Bruch und als Prozentzahl, genau wie
der Desktop sie zeigt — und bei einer als schwierig gekennzeichneten Einheit ihr
[Abzeichen](#schwierige-einheiten). Verwechseln Sie die beiden nicht: **Korrekt** meint die ganze
Lern-Datei, **Einheit korrekt** die Karte vor Ihnen. Eine noch nie gefragte Einheit zeigt
**0/0 (0%)**, damit "noch nie geübt" nie eine Lücke ist. Die Zahl stammt aus der
gespeicherten Statistik der Lern-Datei und nicht aus dem laufenden Durchgang, übersteht
also das Verlassen der Sitzung und das Schließen der App — und sie ändert sich in dem
Moment, in dem Sie die Karte bewerten. In einer Sitzung über **Beide** Richtungen ändert
sie sich, wenn dieselbe Einheit andersherum drankommt, denn jede Richtung führt ihre
eigene Aufzeichnung.

Gehen einer Drill-Sitzung oder einem Durchgang die Karten aus, sagt die App das und
bietet **Sitzung erweitern** an, um weiterzumachen.

**Ihre Statistik wird nach jeder bewerteten Karte gespeichert.** Es bleibt nichts
ungespeichert, und es gibt keine Speichern-Schaltfläche — wichtig auf einem Telefon, wo
Android die App in dem Moment beenden kann, in dem Sie zu etwas anderem wechseln.

## Schwierige Einheiten

Am Desktop können Sie eine Einheit als **schwierig** kennzeichnen, für jede
Abfragerichtung getrennt — von Hand, oder das Programm kennzeichnet die, die Sie immer
wieder falsch beantworten. Die Kennzeichnungen stehen in der Lern-Datei selbst, kommen
also beim Importieren mit, und ein erneuter Import, nachdem Sie am Computer weitere
Einheiten gekennzeichnet haben, bringt die neuen mit. Das Telefon liest sie nur: Es setzt,
entfernt oder findet nie selbst eine schwierige Einheit.

**Das Abzeichen.** Ist eine Karte in der gefragten Richtung schwierig, zeigt sie am Ende
ihrer Einheitenzeile ein Abzeichen: ein Fähnchen für eine manuelle Kennzeichnung, ein
Funkeln für eine automatische, oder beides, gefolgt von **Schwierig**. Halten Sie das
Abzeichen gedrückt, um zu lesen, welche es ist — **Manuelle Kennzeichnung**,
**Automatische Kennzeichnung** oder **Manuelle und automatische Kennzeichnung**. Eine
Einheit, die nur andersherum schwierig ist, zeigt kein Abzeichen, denn bei dieser Frage
ist sie nicht schwer.

**Nur diese üben.** Schalten Sie in **Übung einrichten** **Nur schwierige Einheiten**
ein, um nur die schwierigen Einheiten gefragt zu werden, jede nur in der
Abfragerichtung, in der sie schwierig ist: Bei **Beide** Richtungen wird eine Einheit,
die nur in einer Richtung schwierig ist, nie andersherum gefragt. Das wirkt in jedem
Modus, innerhalb des Einheitenbereichs.

- Die Option zeigt, wie groß die Sitzung wird, in Einheiten: **(3)**, wenn der Bereich
  alle Einheiten enthält, die in der gewählten Abfragerichtung schwierig sind, **(1/3)**,
  wenn er einige auslässt — eine der drei der Lern-Datei. Bei **Beide** zählt eine
  Einheit, die in einer der Richtungen schwierig ist, einmal. Die Zahl folgt **Erste
  Einheit**, **Letzte Einheit** und der Abfragerichtung, während Sie sie ändern; halten
  Sie die Option gedrückt, um sie ausgeschrieben zu lesen.
- Ist im Bereich keine Einheit in der gewählten Abfragerichtung schwierig, sagt die
  Einrichtung das, und **Sitzung starten** bleibt gesperrt, bis Sie die Option
  ausschalten, den Bereich erweitern oder eine andere Abfragerichtung wählen.
- Während der Sitzung zeigt **Übrig**, wie viel davon noch bleibt, wie unter
  [Eine Karte, zwei Antippen](#eine-karte-zwei-antippen) beschrieben.
- Eine beherrschte Einheit fällt wie gewohnt aus einer Drill-Sitzung, behält aber ihre
  Kennzeichnung. Entfernen kann sie nur der Desktop.

## Sprachausgabe

Hier ist das Telefon dem Desktop sogar voraus: Ihr Telefon hat meist schon Stimmen für
weit mehr Sprachen als ein typischer Windows-Rechner, und Kopfhörer stecken ohnehin oft
schon im Ohr.

Neben jedem Feld, das die Maske der Lern-Datei als vorlesbar markiert hat, steht ein
Lautsprecher-Symbol — dieselbe Autoren-Entscheidung, die das Kapitel
[Sprachausgabe](15-speech.md#das-hkchen-vorlesen) des Desktop-Handbuchs
beschreibt und die mit der Lern-Datei selbst mitreist. Auf dem **Frage**-Bildschirm ist
das das Fragefeld, auf dem **Lösung**-Bildschirm sind es das Antwortfeld und etwaige
Bemerkungsfelder; die Frage ist einen Tipp auf den Umschalter **Frage** / **Lösung**
entfernt. Tippen Sie ein Symbol an, und genau dieses Feld wird vorgelesen, in einer
Stimme, die das Telefon für die Sprache des Feldes bereits hat.

Schalten Sie **Antwort automatisch vorlesen** auf dem Bildschirm Sprachausgabe (unten)
ein, wird die Antwort vorgelesen, sobald Sie auf **Antwort zeigen** tippen — richtig oder
falsch macht keinen Unterschied, nichts wird also als Strafe zurückgehalten. Sie wird
einmal je Karte vorgelesen: Der Umschalter **Frage** / **Lösung** wiederholt sie nicht,
und **Antwort zeigen** bei der nächsten Karte bricht Laufendes ab, statt darüber
hinwegzusprechen. Ein `F4` gibt es auf dem Telefon nicht — ein Lautsprecher-Symbol je Feld
lässt sich jederzeit erneut antippen.

Zuhören kostet nichts: Es ist nie ein Versuch, und es verändert keine Statistik.

Den Bildschirm Sprachausgabe erreichen Sie auf zwei Wegen: über das Lautsprecher-Symbol in
der **Übung einrichten** einer Lern-Datei, oder über **Sprachausgabe** im Überlaufmenü
unter **Einstellungen**, auch ohne geöffnete Lern-Datei. Beide bieten dasselbe:

- Eine Zeile je Sprache, die die geöffnete Lern-Datei verwendet (von Übung einrichten) oder
  je Sprache, für die Sie bereits eine Stimme gewählt haben (von Einstellungen) — die auf
  dem Telefon installierten Stimmen dafür, und eine Lautsprecher-Schaltfläche, die einen
  kurzen Satz vorliest, damit Sie eine Stimme vor der Wahl hören können. Eine Sprache, für
  die das Telefon keine Stimme hat, sagt das, statt eine leere Liste zu zeigen.
- **Sprechtempo**, das für alles gilt, was das Telefon vorliest.
- **Antwort automatisch vorlesen**, wie oben beschrieben.

Welche Stimme eine Sprache spricht, ist eine Entscheidung, die **diesem Telefon** gehört
— genau wie sie jedem Desktop-Rechner für sich gehört: Eine Lern-Datei sagt nur, dass ein
Feld Französisch ist, und jedes Gerät entscheidet für sich, welche seiner
Französisch-Stimmen es spricht. Eine vom Desktop übernommene Lern-Datei spricht deshalb
auf dem Telefon, ohne dass Sie die Lern-Datei selbst anfassen; nur die Stimmwahl
unterscheidet sich, weil sie nie Teil der Lern-Datei war.

## Statistik

Das Diagramm-Symbol auf dem Einrichtungsbildschirm einer Lern-Datei öffnet die
**Statistik** dieser Datei:

- **Lerneinheiten gesamt**, **Abgefragte Einheiten**, **Abfrage-Versuche**, **Korrekte
  Versuche** und **Korrekt** über die ganze Lern-Datei.
- Die sieben Trefferquoten-Gruppen — **Perfekt**, **Gut**, **Mittel**, **Unsicher**,
  **Sehr unsicher**, **Nie gewusst** und **Noch nicht abgefragt** — als beschriftete
  Zeilen mit einem Balken, der zeigt, wie viele Einheiten in welche Gruppe fallen.
- **Statistik löschen...**, was nach einer Bestätigung die Vorgeschichte dieser
  Lern-Datei auf diesem Gerät verwirft.

Das ist nur eine Übersicht. Die Einheitenliste, die Filter und das Erzeugen einer neuen
Lern-Datei aus den schlechtesten Einheiten sind Desktop-Funktionen.

## Zwei Geräte, zwei Statistiken

Die Statistik des Telefons gilt **je Gerät, ist so gewollt, und sie wandert nicht mit**.

Android hält die Bibliothek der App in einem privaten Speicher, den weder eine andere App
noch ein PC lesen kann — genau das lässt Statistik auf einem Telefon überhaupt
funktionieren. Ein früherer Ansatz, der neben der ausgewählten Datei schrieb, verlor jede
Zahl, sobald die App neu geöffnet wurde. Der Preis dafür ist, dass es keinen Ordner gibt,
den Sie zum Computer zurückkopieren könnten.

Also: Üben Sie dieselbe Lern-Datei auf beiden Geräten, entstehen zwei voneinander
unabhängige Aufzeichnungen Ihres Fortschritts. Der erneute Import einer aktualisierten
Lern-Datei bewahrt die Zahlen des Telefons, bringt aber nie die des Computers mit.

Weil die Vorgeschichte auf dem Telefon entbehrlich ist, gibt es keinen Export und keine
Sicherung. Android bezieht den App-Speicher in seine eigene automatische Sicherung ein;
geht sie doch verloren, importieren Sie die Lern-Dateien erneut und fangen mit den Zahlen
neu an.

## Einstellungen

Das Überlaufmenü in der oberen Leiste der Bibliothek enthält **Benutzerhandbuch**,
**Einstellungen** und **Programminfo**.

Unter **Einstellungen** stehen fünf Dinge:

**Sprachausgabe** — öffnet den oben beschriebenen Bildschirm
[Sprachausgabe](#sprachausgabe).

**Darstellung** — **System**, **Hell**, **Dunkel**, **Dunkelblau** (die Voreinstellung)
oder **Hellblau**, dieselben fünf Erscheinungsbilder wie am Desktop.

**Sprache** — **Englisch** oder **Deutsch**. Das ist eine Einstellung in der App und
nicht Androids eigene App-Sprache, die es erst ab Android 13 gibt. Sie schaltet jede
Beschriftung der App um und dieses Kapitel mit ihr.

**Mindestabfragen beachten** und **Mindestabfragen** (Voreinstellung aus, 2) — eine
Einheit darf erst dann als beherrscht gelten, wenn sie mindestens so oft abgefragt wurde.
Ohne diese Regel setzt ein einziges glückliches **Gewusst** eine Einheit auf 100 %
Trefferquote, womit sie die Beherrschungsschwelle sofort überspringt und ein Drill-Pool
sich fast so schnell leert, wie Sie tippen können. Schalten Sie sie ein, wenn
"beherrscht" auf dem Telefon dasselbe bedeuten soll wie am Desktop.

**Falsch-Antworten begrenzen** und **Grenze für falsche Antworten** (Voreinstellung aus,
10) — verhindert, dass die Zahl der falschen Antworten einer Einheit unbegrenzt wächst,
sodass eine Karte, mit der Sie einmal Mühe hatten, wieder eine brauchbare Trefferquote
erreichen kann.

Sonst erscheint hier nichts aus den Erweiterten Lernoptionen des Desktops. Groß- und
Kleinschreibung, Akzente, das Urteil *Fast*, vollständige Eingabe und die Uhr bewerten
alle getippte Antworten — und die gibt es hier nicht.

**Darstellung und Sprache** werden in Androids eigenem Einstellungsspeicher abgelegt.
**Die beiden Schutzregeln und Ihre Stimmwahl unter Sprachausgabe** landen in
`learn_anywhere.settings.json`, unter demselben Dateinamen und im selben Format wie am
Desktop, im privaten Dokumentenordner der App.

## App installieren und aktualisieren

Die Begleit-App ist **nicht im Play Store**. Sie wird als APK-Datei verteilt, die Sie
selbst installieren und die neben den Desktop-Downloads auf der Releases-Seite des
Projekts veröffentlicht wird.

- Laden Sie die **arm64**-APK herunter; das ist die richtige Variante für praktisch jedes
  in den letzten zehn Jahren verkaufte Telefon.
- Android fragt beim ersten Mal, ob es Ihrem Browser oder Dateimanager erlaubt sein soll,
  Apps zu installieren. Das ist bei einer App, die nicht aus einem Store kommt, normal.
- Zum Aktualisieren installieren Sie die neuere APK einfach über die alte. Bibliothek und
  Statistik bleiben erhalten.

Zwei Dinge können schiefgehen:

- **Android verweigert die Installation ohne brauchbare Begründung**, auf einem Telefon,
  auf dem die App schon ist. Fast immer ist das eine **ältere Version**: Android
  installiert keinen Stand, der älter ist als der installierte. Ein vorheriges
  Deinstallieren behebt es, kostet aber Bibliothek und Statistik.
- **Sie haben die falsche Architektur erwischt.** Auf einem gewöhnlichen Telefon läuft
  nur der arm64-Stand; die übrigen Dateien einer Veröffentlichung sind für Emulatoren und
  deutlich ältere Geräte.

Version und Lizenz der App stehen unter **Programminfo**. Learn Anywhere ist freie
Software unter der GNU General Public License v3.0, auf dem Telefon genau wie am Desktop.
