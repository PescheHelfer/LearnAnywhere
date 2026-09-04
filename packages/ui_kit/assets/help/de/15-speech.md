# Sprachausgabe

Eine Lern-Datei weiss, dass ein Wort französisch ist. Solange Sie es dem Programm nicht
sagen, weiss es das nicht — und ein Wort, das Sie nur lesen können, ist ein Wort, das Sie
nicht aussprechen können. Die Sprachausgabe beginnt in der Maske: Sie legen fest, welche
Sprache jedes Feld enthält und welche Felder vorgelesen werden dürfen.

In dieser Version wird noch nichts vorgelesen. Was Sie hier einstellen, wird in der Maske
gespeichert und reist mit Ihren Lern-Dateien mit, ist also nicht umsonst — siehe
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

Diese Version hält nur die Absicht fest — kein Feld wird vorgelesen, und ausserhalb des
Mask Editors gibt es keine Einstellung zur Sprachausgabe. Was Sie hier festlegen, ist
das, womit das Vorlesen arbeiten wird, sobald es kommt, auf den Systemen, die sprechen
können: Windows und die Android-Begleit-App. Linux hat keine Sprachausgabe und sagt das
klar, statt eine Einstellung zu zeigen, die nichts tut.
