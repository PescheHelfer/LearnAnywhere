# Erste Schritte

Dieses Kapitel führt von der frischen Installation bis zur ersten abgeschlossenen
Übungssitzung. Es setzt voraus, dass Sie eine Lern-Datei zur Hand haben; falls nicht,
zeigen [Der Mask Editor](05-mask-editor.md) und
[Lerneinheiten bearbeiten](04-unit-editor.md), wie Sie eine von Grund auf anlegen.

## Installation

Laden Sie es von der
[Releases-Seite](https://github.com/PescheHelfer/LearnAnywhere/releases/latest) herunter.

**Windows.** Entpacken Sie den heruntergeladenen Ordner an einen beliebigen Ort — die
Dateien darin gehören zusammen — und starten Sie `LearnAnywhere.exe` aus diesem Ordner
heraus. Das Programm braucht keine Installation und schreibt nichts außerhalb Ihres
eigenen Benutzerprofils.

**Linux.** Learn Anywhere wird als AppImage ausgeliefert. Machen Sie es ausführbar und
starten Sie es:

```
chmod +x Learn_Anywhere-*.AppImage
./Learn_Anywhere-*.AppImage
```

Die Android-Begleit-App ist noch nicht veröffentlicht.

## Der erste Start

Das Programm öffnet den Bildschirm **Arbeitsbereich**, in dem noch nichts geladen ist;
entsprechend meldet er **Keine Datei geladen**. Alles Weitere erreichen Sie über die
Menüleiste am oberen Rand:

**Datei · Edit · Lern · Statistik · Lexikon · Optionen · Hilfe**

**Statistik** und **Lexikon** sind einzelne Befehle und keine Menüs — ein Klick öffnet
den jeweiligen Bildschirm direkt. Jedes Menü lässt sich auch mit `Alt` und dem
unterstrichenen Buchstaben öffnen, zum Beispiel `Alt+D` für **Datei**. Die vollständige
Liste steht in [Tastaturbefehle](12-keyboard-shortcuts.md).

Sobald etwas geladen ist, wird der Arbeitsbereich zur Übersicht: Pfad der Lern-Datei,
Name der verwendeten Maske, Anzahl der Lerneinheiten und wie viel davon Sie bereits
geübt haben. Mit `Esc` kommen Sie von jedem anderen Bildschirm hierher zurück.

## Die drei Dateiarten

Learn Anywhere hält Ihr Material in drei getrennten Dateien. Alle drei sind reiner
UTF-8-JSON-Text — es gibt keine Datenbank, und Sie können sie mit jedem Editor lesen
oder sichern.

| Endung | Inhalt |
|---|---|
| `.vok` | Eine **Lern-Datei**: Ihre Lerneinheiten und eine schreibgeschützte Kopie der Maske, die sie formt |
| `.inf` | Eine **Maske**: die bearbeitbare Definition dessen, wie eine Karte aussieht |
| `.sta` | **Statistik**: wie oft jede Lerneinheit abgefragt und wie oft sie richtig beantwortet wurde |

Eine Lern-Datei ist in sich vollständig — sie trägt ihre eigene Kopie der Maske und
öffnet daher auch dann korrekt, wenn die `.inf`-Datei fehlt. Die `.inf`-Datei ist die
Kopie, die Sie *bearbeiten*; Änderungen daran lassen sich anschließend in die
Lern-Dateien übernehmen, die diese Maske verwenden. [Grundbegriffe](02-concepts.md)
erklärt den Zusammenhang vollständig.

Die Statistik liegt neben der Lern-Datei statt in ihr. So können Sie dieselbe Lern-Datei
unter mehreren Namen üben, einen misslungenen Durchgang löschen oder eine Sitzung
archivieren, ohne Ihr Material anzufassen.

## Eine Lern-Datei öffnen

Wählen Sie **Datei ▸ Lerneinheiten laden...** und wählen Sie eine `.vok`-Datei aus. Der
Arbeitsbereich füllt sich mit den Angaben zur Datei.

Der Arbeitsbereich merkt sich die drei zuletzt geöffneten Lern-Dateien unter **Zuletzt
verwendete Lern-Dateien**, die neueste zuoberst. Jeder Eintrag ist eine anklickbare
Zeile; ein Klick öffnet die Datei, ohne Umweg über den Dateidialog. Die Liste steht
beim nächsten Programmstart bereit — und auch dann, wenn bereits eine Lern-Datei
geladen ist, denn genau dann ist der Wechsel zu einer anderen Sprache am nützlichsten.
Die gerade geöffnete Datei wird ausgelassen; die Liste bietet also immer nur ein
anderes Ziel an.

Wenn Sie mit der Maus über einen Eintrag fahren, wird der vollständige Pfad angezeigt.
Verschieben oder löschen Sie eine Lern-Datei, bleibt sie in der Liste stehen — grau
dargestellt, statt stillschweigend zu verschwinden. So sehen Sie einen ganzen
verschobenen Ordner, statt ihn unbemerkt zu verlieren. Ein solcher Eintrag öffnet
nichts mehr; ein Klick darauf meldet **Datei nicht gefunden** samt dem gesuchten Pfad.

Wenn Sie zu der Datei eine Statistik führen, schalten Sie **Optionen ▸ Statistiken ▸
Statistiken automatisch laden** ein; dann wird die passende `.sta`-Datei beim Öffnen
automatisch mitgeladen. Siehe [Arbeiten mit Dateien](03-managing-files.md).

## Die erste Sitzung

Wählen Sie **Lern ▸ Übung einrichten**. Der Einrichtungsbildschirm fragt vier Dinge ab:

- **Abfragerichtung** — in welche Richtung gefragt wird. Eine Maske definiert zwei
  Richtungen, zum Beispiel Deutsch → Französisch und Französisch → Deutsch.
- **Modus** — **Stufenlernen**, **Drill-Modus**, **Endlos-Modus** oder
  **Einmal durchgehen**. Wenn Sie unsicher sind, beginnen Sie mit **Stufenlernen**: es
  zeigt zunächst fast die ganze Lösung und nimmt die Hilfe weg, sobald Sie besser
  werden.
- **Einheiten mischen** — in zufälliger Reihenfolge abfragen statt in Dateireihenfolge.
- **Erste Einheit** und **Letzte Einheit** — die Übung auf einen Abschnitt begrenzen,
  etwa auf die Lektion dieser Woche. Unverändert lassen heißt: alles üben.

Drücken Sie **Sitzung starten**. Zu jeder Karte zeigt das Programm die Frage-Felder und
ein leeres Feld für die Antwort. Tippen Sie Ihre Antwort und drücken Sie `Enter` (oder
`F3`), um sie prüfen zu lassen. Das Programm zeigt dann, ob sie richtig war, und mit
einem weiteren `Enter` geht es zur nächsten Karte.

Wenn Sie lieber nicht tippen möchten, schalten Sie die getippte Antwort ab: das Programm
zeigt dann die Karte, wartet auf **Aufdecken** (`F10`) und lässt Sie selbst bewerten.

Mit `Esc` verlassen Sie die Sitzung jederzeit. Dabei geht nichts verloren: der
[Drill-Modus](06-learning-sessions.md) baut seine Liste der noch nicht beherrschten
Karten jedes Mal neu aus Ihrer Statistik auf. Sie können also mittendrin aufhören und
Tage später weitermachen — auch nach einem Neustart des Programms.

## Was Sie als Nächstes lesen sollten

- [Grundbegriffe](02-concepts.md) — die Begriffe, die im weiteren Handbuch verwendet
  werden.
- [Lernsitzungen](06-learning-sessions.md) — was die einzelnen Modi tatsächlich tun.
- [Statistik](09-statistics.md) — Ergebnisse lesen und aus den Karten, die Sie immer
  wieder falsch haben, eine eigene Lern-Datei bauen.
