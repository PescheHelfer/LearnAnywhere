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
- Statistik je Lern-Datei, gespeichert nach jeder bewerteten Karte.
- Einstellungen für Darstellung und Sprache sowie die beiden unten beschriebenen
  Schutzregeln.

Bewusst nicht enthalten sind:

- **Tippen.** Es wird nie eine Antwort eingegeben, also wird auch nichts verglichen oder
  bewertet.
- **Stufenlernen.** Dieser Modus fragt eine getippte Antwort mit immer weniger
  Hilfestellung ab und kann ohne Tippen nicht existieren.
- **Bearbeiten.** Keine Bearbeitung von Lerneinheiten, kein Mask Editor, kein Lexikon.
  Lern-Dateien entstehen am Desktop.
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

Jeder Eintrag zeigt den Namen der Lern-Datei und die Anzahl **Einheiten**. Ein Tippen
öffnet den Eintrag; das Papierkorb-Symbol bietet **Löschen** an, wodurch die Lern-Datei
**und ihre Statistik von diesem Gerät** entfernt werden.

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
| **Erste Einheit** / **Letzte Einheit** | Nur einen Teil der Lern-Datei üben. |

Ihre Auswahl wird gemerkt — außer dem Einheitenbereich, der beim Öffnen einer Lern-Datei
jedes Mal zurückgesetzt wird, weil ein Bereich, der zu einer Datei passt, für die nächste
bedeutungslos ist.

**Sitzung starten** beginnt die Übung. Eine Option für getippte Antworten gibt es hier
nicht: auf dem Telefon ist sie immer aus.

## Eine Karte, zwei Antippen

Jede Karte braucht genau zwei Antippen.

**Erstes Antippen.** Die Karte zeigt die **Frage** und eine Schaltfläche,
**Antwort zeigen**.

**Zweites Antippen.** Die Karte zeigt nun die **Lösung** und etwaige **Bemerkungen**, mit
drei Schaltflächen darunter:

- **Gewusst** — zählt als korrekter Versuch.
- **Nicht gewusst** — zählt als falscher Versuch.
- **Nicht zählen** — zeigt Ihnen die Karte, ohne etwas aufzuzeichnen. Nützlich, wenn Sie
  gestört wurden oder etwas nachschlagen wollen, ohne die Zahlen zu verfälschen.

Was Sie auch antippen: es bewertet die Karte und geht zugleich zur nächsten weiter, ein
eigener Schritt zum Weiterblättern entfällt. Das entspricht dem Desktop, wo Sie die
Lösung anzeigen und dann eine von drei Tasten drücken.

Über der Karte verfolgt eine Leiste die Sitzung: **Beherrscht**, **Übrig** und
**Korrekt** für den laufenden Durchgang.

Gehen einer Drill-Sitzung oder einem Durchgang die Karten aus, sagt die App das und
bietet **Sitzung erweitern** an, um weiterzumachen.

**Ihre Statistik wird nach jeder bewerteten Karte gespeichert.** Es bleibt nichts
ungespeichert, und es gibt keine Speichern-Schaltfläche — wichtig auf einem Telefon, wo
Android die App in dem Moment beenden kann, in dem Sie zu etwas anderem wechseln.

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

Unter **Einstellungen** stehen vier Dinge:

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
**Die beiden Schutzregeln** landen in `learn_anywhere.settings.json`, unter demselben
Dateinamen und im selben Format wie am Desktop, im privaten Dokumentenordner der App.

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
