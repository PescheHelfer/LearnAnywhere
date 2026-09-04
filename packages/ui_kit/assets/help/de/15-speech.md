# Sprachausgabe

Eine Lern-Datei weiss, dass ein Wort französisch ist. Solange Sie es dem Programm nicht
sagen, weiss es das nicht — und ein Wort, das Sie nur lesen können, ist ein Wort, das Sie
nicht aussprechen können. Die Sprachausgabe beginnt in der Maske: Sie legen fest, welche
Sprache jedes Feld enthält und welche Felder vorgelesen werden dürfen.

Hat ein Feld eine Sprache und die Erlaubnis, gesprochen zu werden, liest ein
Lautsprecher-Symbol daneben es in einer Lernsitzung vor — siehe
[Felder vorlesen lassen](#felder-vorlesen-lassen). Schalten Sie das automatische
Vorlesen ein, liest sich die Antwort bei jedem Aufdecken von selbst vor, und `F4` gibt
sie erneut aus — siehe
[Die Antwort automatisch vorlesen](#die-antwort-automatisch-vorlesen). Welche *Stimme*
spricht, entscheidet
Ihr Rechner, nicht Ihre Lern-Datei; welche seiner Stimmen es sein soll, wählen Sie unter
[Eine Stimme aussuchen](#eine-stimme-aussuchen). Noch ist nicht alles da: siehe
[Was noch fehlt](#was-noch-fehlt).

## Wo die Sprachausgabe eingestellt wird

Im [Mask Editor](05-mask-editor.md#felder) hat jedes Feld zwei Spalten nach seinen beiden
Rollen-Spalten:

| Spalte | Bedeutung |
|---|---|
| Vorlesesprache | Die Sprache, in der dieses Feld geschrieben ist, aus einer Liste gewählt |
| Vorlesen | Ob dieses Feld vorgelesen werden darf |

Beide gehören zum **Feld**, nicht zu einer Richtung: Französisch bleibt Französisch, ob
gefragt oder geantwortet wird, also gilt eine Einstellung für beide Richtungen.

## Eine Vorlesesprache wählen

Die Liste bietet die Sprachen, für die dieses Programm gebaut ist, jeweils mit den
regionalen Varianten, die wirklich anders klingen — **"Deutsch (Deutschland) (de-DE)"**,
**"Deutsch (Österreich) (de-AT)"**, **"Deutsch (Schweiz) (de-CH)"**,
**"English (United Kingdom) (en-GB)"**, **"English (United States) (en-US)"**,
**"Français (France) (fr-FR)"**, **"Français (Canada) (fr-CA)"** und
**"Italiano (Italia) (it-IT)"**. Wählen Sie die Aussprache, die Sie lernen wollen: eine
britische und eine amerikanische Stimme sagen dasselbe Wort verschieden, und genau darum
geht es bei dieser Wahl.

Zwei Einträge sind keine Sprachen:

- **"(keine)"** ist die Voreinstellung und bedeutet, dass das Feld nie vorgelesen wird.
  Jede Maske, die Sie heute haben, steht hier — an Ihren bestehenden Lern-Dateien ändert
  sich also nichts.
- **"Andere..."** fragt nach einem selbst getippten Sprachkürzel, für eine Sprache, die
  die Liste nicht anbietet — `es-ES` für Spanisch, `ru-RU` für Russisch, `pt-BR` für
  brasilianisches Portugiesisch. Die Form ist eine Sprache, dahinter optional eine
  Region, mit Bindestrich verbunden. Ein Wort wie `spanisch` ist kein Kürzel, und das
  wird Ihnen gesagt: **"Kein Sprachkürzel. Form wie fr-FR verwenden."** Ist es
  angenommen, steht das Kürzel in der Liste dieses Feldes; beim erneuten Öffnen der
  Liste ist es also noch da. Ein weiteres Feld derselben Sprache braucht das Kürzel
  erneut.

## Das Häkchen Vorlesen

**Vorlesen** entscheidet, ob ein Feld überhaupt vorgelesen werden darf. Es wird für Sie
gesetzt, sobald Sie ein Feld zur **Antwort** einer der beiden Richtungen machen, denn das
ist fast immer das Feld, das zu hören sich lohnt.

Es wird nie für Sie entfernt. Nehmen Sie es weg — eine Geschlechts-Spalte, die nur mit
`m` oder `f` beantwortet wird, muss niemand hören —, bleibt es bei jeder späteren
Änderung dieses Feldes weg. Das Programm schlägt nur vor; entschieden wird von Ihnen.

Ein Feld mit gesetztem **Vorlesen**, aber ohne gewählte Vorlesesprache kann nicht
vorgelesen werden: es fehlt die Angabe, welche Stimme es lesen soll.

## Felder vorlesen lassen

In einer [Lernsitzung](06-learning-sessions.md) steht neben jedem Feld, das vorgelesen
werden darf und dessen Wert auf dem Bildschirm steht, ein kleines Lautsprecher-Symbol.
Ein Klick darauf liest genau dieses Feld vor, mit einer Stimme, die Ihr Rechner für die
Sprache des Feldes bereits hat. Nichts wird heruntergeladen, nichts verlässt Ihren
Rechner.

Es gibt eine Regel, und sie braucht keine Ausnahmen: **das Symbol steht dort, wo der Wert
seines Feldes steht.** Ein Frage-Feld trägt es, sobald die Karte erscheint — Sie können
das Wort also hören, während Sie noch über der Antwort brüten. Ein Antwort- oder
Bemerkungs-Feld bekommt es in dem Moment, in dem es aufgedeckt wird, also dann, wenn Sie
es ohnehin lesen können. Die Lösung vorab zu hören, ist damit unmöglich.

Die Regel gilt auch im [Stufenlernen](07-level-learning.md), und dort zahlt sie sich aus:
auf der obersten Stufe steht die ganze Lösung zum Lesen und Einprägen auf dem Bildschirm,
trägt also ein Symbol — das Wort zu hören ist genau der Zweck dieses Schritts. Mit
**Verdecken & tippen** verschwindet das Symbol zusammen mit der Lösung.

Kein Symbol steht neben:

- einem Feld ohne Häkchen bei **Vorlesen**,
- einem Feld mit **"(keine)"** als Vorlesesprache,
- einem versteckten Feld (einem ohne Namen),
- einem Antwort- oder Bemerkungs-Feld vor dem Prüfen,
- einem Feld, das diese Einheit leer lässt.

Vorgelesen wird genau das, was im Feld steht, samt allem, was Sie durchgestrichen haben:
das Programm sagt, was geschrieben wurde, und bessert nichts aus.

Zuhören kostet nichts. Es ist nie ein Versuch, bewegt keine
[Statistik](09-statistics.md) und kann Sie auf der
[Stufenleiter](07-level-learning.md) weder hinauf- noch hinunterbringen. Hören Sie ein
Wort zehnmal an, wenn es hilft.

## Die Antwort automatisch vorlesen

Für jedes einzelne Wort auf ein Symbol zu klicken, wird schnell mühsam. Setzen Sie unter
[Eine Stimme aussuchen](#eine-stimme-aussuchen) das Häkchen bei **Antwort automatisch
vorlesen**, und die Antwort wird vorgelesen, sobald sie aufgedeckt ist — Sie können die
Maus liegen lassen und weitertippen.

Vorgelesen wird die Antwort und nur die Antwort: jedes Feld, das vorgelesen werden darf
und in der gefragten Richtung die Rolle Antwort hat, in der Reihenfolge der Maske. Die
Frage wird nicht vorgelesen — Sie sehen sie die ganze Zeit — und ein Bemerkungs-Feld
ebenso wenig, denn es ist in beiden Richtungen eine Bemerkung. Bemerkungen behalten ihr
eigenes Symbol, ein Beispielsatz ist also weiterhin einen Klick entfernt.

Vorgelesen wird, ob Sie richtig lagen, falsch lagen oder ein *Fast* bekommen haben.
Gerade ein Fehler ist der Moment, in dem es am meisten bringt, das Wort richtig
ausgesprochen zu hören; nichts wird als Strafe zurückgehalten. Es funktioniert auf jeder
Stufe des [Stufenlernens](07-level-learning.md) gleich und auch beim blossen Aufdecken
ohne Tippen.

Drei Einzelheiten, die Ihnen binnen zehn Sekunden auffallen würden, wären sie falsch:

- Vorgelesen wird **einmal** je aufgedeckter Einheit. Das Durchschalten der Antwortansicht
  mit `F9` wiederholt nichts.
- Das Aufdecken einer neuen Einheit **bricht** ab, was noch gesprochen wird, statt sich
  dahinter anzustellen. Wer `Enter` durch zehn Einheiten hält, hört das zehnte Wort und
  nicht alle zehn übereinander.
- Eine Einheit ohne etwas zum Vorlesen — kein Antwortfeld mit **Vorlesen**, oder nichts
  darin geschrieben — bleibt einfach stumm. Es wird nichts gemeldet, und es geht nichts
  schief.

`F4` liest dasselbe jederzeit erneut vor, ob eingeschaltet oder nicht. Es gibt genau das
aus, was das automatische Vorlesen ausgibt; so gibt es eine Regel zu lernen und nicht
zwei. Vor dem Aufdecken gibt es nichts vorzulesen — `F4` kann Ihnen die Lösung nicht
vorab verraten. Die einzige Ausnahme ist die oberste Stufe der
[Stufenleiter](07-level-learning.md), wo die Lösung zum Einprägen auf dem Bildschirm
steht: dort trägt sie ein Symbol, und dort liest `F4` sie ebenfalls vor.

Ist das Häkchen nicht gesetzt, sagt das Programm nie etwas, ohne dass Sie es verlangen —
per Symbol oder per `F4`. So oder so ist Zuhören nie ein Versuch: Hören Sie ein Wort
zehnmal an, und Ihre [Statistik](09-statistics.md) und Ihr Platz auf der Stufenleiter
stehen genau dort, wo sie vorher standen.

## Wenn nichts gesprochen wird

Eine Stimme gehört zum Rechner, an dem Sie sitzen, nie zur Lern-Datei. Das Programm nimmt
das Erste, was es bekommen kann: die Stimme, die Sie unter
[Eine Stimme aussuchen](#eine-stimme-aussuchen) für diese Sprache gewählt haben; dann
eine Stimme für genau diese Sprache; dann irgendeine Stimme derselben Sprache aus einer
anderen Region — eine kanadisch-französische Stimme liest also ein Feld in
Frankreich-Französisch vor, statt es stumm zu lassen.

Ist keine von beiden installiert, bleibt das Symbol stehen und sagt Ihnen beim Benutzen,
woran es liegt: **"Keine installierte Stimme spricht fr-FR. Das Kapitel "Sprachausgabe"
im Benutzerhandbuch (F1) erklärt, wie Sie eine hinzufügen."** Das Symbol verschwindet
bewusst nicht. Ein fehlendes Symbol sähe genau wie ein Feld aus, für das niemand das
Vorlesen eingeschaltet hat, und Sie könnten die beiden Fälle nicht unterscheiden.

**Optionen ▸ Sprachausgabe...** sagt dasselbe schon vor der Sitzung, und zwar für alle
Sprachen auf einmal: Eine Zeile mit **"Dieser Computer hat keine Stimme für it-IT"** ist
diese Sprache, die Ihnen vorab mitteilt, dass sie stumm bleiben wird. Der nächste
Abschnitt sagt, wie Sie das ändern.

## Eine Stimme unter Windows installieren

Windows installiert Sprachstimmen zusammen mit seinen **Sprachfunktionen**, jeweils eine
Sprache auf einmal. Es gibt keine gesonderte Liste von Stimmen zum Kaufen oder
Herunterladen, und eine so hinzugefügte Sprache kostet nichts.

**Windows 11.** Öffnen Sie die **Einstellungen** von Windows, gehen Sie zu **Zeit und
Sprache ▸ Sprache und Region** und drücken Sie **Sprache hinzufügen**. Wählen Sie die
gewünschte — *Français (France)* für `fr-FR`, *Deutsch (Deutschland)* für `de-DE`,
*Italiano (Italia)* für `it-IT`, *English (United Kingdom)* für `en-GB`. Lassen Sie auf
der folgenden Seite **Sprachfunktionen installieren** den Punkt **Sprachausgabe** (in
manchen Versionen **Text-zu-Sprache**) angehakt: Dieser Bestandteil *ist* die Stimme,
und ohne ihn wird die Sprache ohne Stimme installiert. Die übrigen Bestandteile —
Anzeigesprache, Handschrift, Tastatur — braucht die Sprachausgabe nicht.

**Windows 10.** Öffnen Sie **Einstellungen ▸ Zeit und Sprache ▸ Spracherkennung**.
Drücken Sie unter **Stimmen verwalten** auf **Stimmen hinzufügen** und wählen Sie die
gewünschte Sprache. Fehlt sie dort, fügen Sie sie zuerst unter **Zeit und Sprache ▸
Sprache ▸ Sprache hinzufügen** hinzu und kehren Sie dann zu **Spracherkennung** zurück.

**Jede Region ist eine eigene Stimme.** `fr-FR` und `fr-CA` sind zwei getrennte
Installationen, ebenso `en-GB` und `en-US`. Ist ein Feld kanadisches Französisch und nur
Frankreich-Französisch installiert, nimmt Learn Anywhere die französische Stimme, statt
stumm zu bleiben — richtig ausgesprochen wird es aber erst mit der kanadischen.

Eine neu installierte Stimme wird gefunden, sobald Sie das nächste Mal eine Lernsitzung
oder den Bildschirm **Optionen ▸ Sprachausgabe...** öffnen. Nichts muss neu gestartet
werden, und in Learn Anywhere ist für eine neue Stimme nichts einzurichten.

## Eine Stimme aussuchen

Unter **Optionen ▸ Sprachausgabe...** entscheiden Sie, *welche* Stimme Ihres Computers
welche Sprache spricht, wie schnell alles vorgelesen wird und ob die Antwort von selbst
vorgelesen wird.

**Antwort automatisch vorlesen** steht zuoberst auf dem Bildschirm. Es ist aus, bis Sie
es einschalten, es wird über Sitzungen hinweg gemerkt, und was es tut, steht unter
[Die Antwort automatisch vorlesen](#die-antwort-automatisch-vorlesen).

Der Bildschirm zeigt eine Zeile je Sprache: jede Sprache, die die Maske der geöffneten
Lern-Datei verwendet, sowie jede, für die Sie bereits eine Stimme gewählt haben — eine
Wahl für eine andere Lern-Datei geht also weder verloren noch aus dem Blick. Ohne
geöffnete Lern-Datei bleiben nur die von Ihnen eingerichteten Sprachen übrig.

Jede Zeile bietet:

| | |
|---|---|
| **Stimme** | Die für diese Sprache installierten Stimmen, die beste zuerst. **"Automatisch"** ist der Anfangszustand: Die Wahl bleibt beim Programm, genau wie unter [Wenn nichts gesprochen wird](#wenn-nichts-gesprochen-wird) beschrieben. |
| Die Lautsprecher-Schaltfläche | Liest einen kurzen Beispielsatz in der Sprache und der gewählten Stimme dieser Zeile vor, damit Sie eine Stimme hören, bevor Sie sich für sie entscheiden. |

Eine Sprache, für die Ihr Computer keine Stimme hat, zeigt diesen Satz statt einer
leeren Liste.

**Sprechtempo** steht über den Zeilen und gilt für *alles*, was das Programm sagt — für
die Beispielsätze auf diesem Bildschirm ebenso wie für jedes Lautsprecher-Symbol in
einer Sitzung. In einer kaum vertrauten Sprache ist es die nützlichste Einstellung hier:
verlangsamt wird aus einem Wort, das Sie gar nicht verstanden haben, ein Wort, dessen
Teile Sie hören können. Es wird als Anteil der normalen Geschwindigkeit jeder Stimme
eingestellt, und zwar nach Gehör — die Stimmen legen es etwas unterschiedlich aus.

Sowohl die Stimmen als auch das Tempo werden auf **diesem Rechner** gemerkt, in der
Datei aus [Einstellungen](11-settings.md#wo-einstellungen-liegen). Nichts davon wird je
in eine Lern-Datei geschrieben: Eine Lern-Datei, die die Stimmennamen des einen Rechners
auf einen anderen trägt, trüge etwas Bedeutungsloses mit sich. Die Lern-Datei sagt nur,
dass ein Feld französisch ist; welche seiner französischen Stimmen es spricht,
entscheidet jeder Rechner selbst.

Wird eine gewählte Stimme später deinstalliert, geht nichts kaputt: Die Zeile fällt auf
**"Automatisch"** zurück, und das Feld wird von dem gesprochen, was sonst passt — genau
so, als hätten Sie nie gewählt.

Auf einem Rechner, der nicht sprechen kann — heute **Linux** —, fehlt der Menüpunkt
ganz, statt leer dazustehen. Ein Bildschirm zur Wahl zwischen Stimmen, die ein Rechner
nicht hat, böte nichts.

## Was mitreist und was nicht

Vorlesesprache und **Vorlesen** stehen in der Maske, folgen einer Lern-Datei also auf
einen anderen Computer oder aufs Telefon, genau wie Name oder Länge eines Feldes. Beides
zu ändern ist ungefährlich: dabei können keine gespeicherten Daten verloren gehen, also
[aktualisieren sich](05-mask-editor.md#lern-dateien-synchron-halten) Lern-Dateien aus
dieser Maske ohne Rückfrage.

Welche *Stimme* eine Sprache spricht, steht bewusst nicht in der Lern-Datei. Eine Stimme
gehört zu dem Rechner, auf dem sie installiert ist; eine Lern-Datei, die die
Stimmennamen des einen Rechners auf einen anderen trägt, trüge etwas Bedeutungsloses mit
sich herum.

## Was noch fehlt

Die Sprachausgabe läuft unter **Windows** und in der **Android-Begleit-App** — siehe
deren eigenes Kapitel, [Die Android-Begleit-App](14-android-companion.md#sprachausgabe).
**Linux** hat keine — dort erscheint gar kein Lautsprecher-Symbol, statt eines, das beim
Klicken nichts täte, und **Optionen ▸ Sprachausgabe...** steht nicht im Menü.
