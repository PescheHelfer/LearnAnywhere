# Sprachausgabe

Eine Lern-Datei weiss, dass ein Wort französisch ist. Solange Sie es dem Programm nicht
sagen, weiss es das nicht — und ein Wort, das Sie nur lesen können, ist ein Wort, das Sie
nicht aussprechen können. Die Sprachausgabe beginnt in der Maske: Sie legen fest, welche
Sprache jedes Feld enthält und welche Felder vorgelesen werden dürfen.

Hat ein Feld eine Sprache und die Erlaubnis, gesprochen zu werden, liest ein
Lautsprecher-Symbol daneben es in einer Lernsitzung vor — siehe
[Felder vorlesen lassen](#felder-vorlesen-lassen). Welche *Stimme* spricht, entscheidet
Ihr Rechner, nicht Ihre Lern-Datei, und noch ist nicht alles da: siehe
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

## Wenn nichts gesprochen wird

Eine Stimme gehört zum Rechner, an dem Sie sitzen, nie zur Lern-Datei. Das Programm sucht
eine passende: zuerst eine Stimme für genau diese Sprache, dann irgendeine Stimme
derselben Sprache aus einer anderen Region — eine kanadisch-französische Stimme liest
also ein Feld in Frankreich-Französisch vor, statt es stumm zu lassen.

Ist keine von beiden installiert, bleibt das Symbol stehen und sagt Ihnen beim Benutzen,
woran es liegt: **"Keine installierte Stimme spricht fr-FR. Das Kapitel "Sprachausgabe"
im Benutzerhandbuch (F1) erklärt, wie Sie eine hinzufügen."** Das Symbol verschwindet
bewusst nicht. Ein fehlendes Symbol sähe genau wie ein Feld aus, für das niemand das
Vorlesen eingeschaltet hat, und Sie könnten die beiden Fälle nicht unterscheiden.

Windows installiert Sprachstimmen zusammen mit seinen Sprachfunktionen: Öffnen Sie die
**Einstellungen** von Windows, gehen Sie zu **Zeit und Sprache** und fügen Sie die
gewünschte Sprache hinzu — unter Windows 10 im Bereich **Spracherkennung**, wo
**Stimmen verwalten** die Schaltfläche **Stimmen hinzufügen** anbietet; unter Windows 11
unter **Sprache und Region**, indem Sie die Sprache hinzufügen und ihre Sprachausgabe
mitwählen. Learn Anywhere findet eine neu installierte Stimme, sobald Sie das nächste
Mal eine Lernsitzung öffnen.

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

Vorgelesen wird auf Anforderung, Feld für Feld, per Klick auf das Symbol. Die Antwort
beim Aufdecken automatisch vorlesen zu lassen, eine Taste, die das wiederholt, die Wahl,
*welche* Ihrer installierten Stimmen eine Sprache spricht, und ein langsameres
Sprechtempo kommen noch. Ausserhalb des Mask Editors gibt es bisher keine Einstellung
zur Sprachausgabe: das Programm wählt selbst eine passende Stimme.

Die Sprachausgabe läuft unter **Windows**. **Linux** hat keine — dort erscheint gar kein
Lautsprecher-Symbol, statt eines, das beim Klicken nichts täte. Auch die
**Android-Begleit-App** kann noch nicht sprechen.
