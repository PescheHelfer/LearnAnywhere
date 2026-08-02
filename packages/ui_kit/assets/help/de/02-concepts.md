# Grundbegriffe

Learn Anywhere weiß nicht, was eine Sprache, eine Formel oder ein chemisches Symbol
ist. Es kennt nur **Masken**, **Lern-Dateien**, **Lerneinheiten**, **Kategorien**,
**Felder**, **Rollen** und **Abfragerichtungen** — ein kleines, fachunabhängiges
Vokabular, auf dem alles andere in diesem Handbuch aufbaut.

## Maske: die Form einer Karte

Eine **Maske** ist das Formular, das Ihre Karten ausfüllen. Sie definiert:

- Einen **Namen**, rein zu Ihrer eigenen Orientierung.
- Zwei **Namen der Abfragerichtungen** — die beiden Richtungen, in denen gefragt werden
  kann, zum Beispiel "Deutsch" und "Französisch". In welche Richtung geübt wird, wählen
  Sie in den [Lernsitzungen](06-learning-sessions.md).
- Bis zu 20 **Kategorien**, jede eine benannte Gruppe von bis zu 20 **Feldern**.

Eine Maske weiß nichts über den *Inhalt* einer Karte, nur über ihre *Form*: wie viele
Informationen zu ihr gehören und welche Rolle jede davon spielt.

## Kategorie und Feld

Eine **Kategorie** fasst die Felder zusammen, die zu einer Art von Karte gehören — eine
Vokabel-Maske könnte eine Kategorie "Substantiv" mit Feldern für das Wort, seinen
Artikel und eine Pluralform haben, und eine eigene Kategorie "Verb" mit Feldern für den
Infinitiv und die Stammformen. Jede Lerneinheit gehört zu genau einer Kategorie.

Ein **Feld** ist eine Information: ein Name, eine maximale **Länge** (1 bis 80 Zeichen —
Felder sind einzeilig und werden in einer nichtproportionalen Schrift dargestellt, ihre
Breite hängt also nie davon ab, was eingetragen wird), eine **Gleichheitsgruppe** und
eine **Rolle** in jeder Richtung.

Ein Feld ohne Namen ist **verdeckt**: es enthält weiterhin Daten und kann weiterhin
abgefragt werden, erscheint aber nie als beschriftete Zeile im Editor oder in
Suchergebnissen — nützlich für ein Feld, das Sie zur eigenen Buchführung ausfüllen,
nicht zum Abfragen.

## Gleichheitsgruppe

Felder, die dieselbe von Null verschiedene **Gleichheitsgruppen**-Nummer tragen, gelten
als austauschbare Antworten. Tragen sowohl "Pluralform" als auch "alternative
Pluralform" die Gleichheitsgruppe `1`, wird in einer Sitzung jede der beiden akzeptiert
— das Programm prüft Ihre Antwort gegen jedes Feld der Gruppe, nicht nur gegen das
aktuell als primäre Antwort angezeigte. Felder mit der Gleichheitsgruppe `0` (Standard)
sind mit nichts verknüpft.

## Rolle: als was ein Feld abgefragt wird

Jedes Feld trägt in jeder der beiden Abfragerichtungen der Maske eine **Rolle**, im
[Mask Editor](05-mask-editor.md) als einzelner Buchstabe angezeigt:

| Rolle | Bedeutung |
|---|---|
| `Q` | Frage — wird als Aufgabenstellung gezeigt |
| `A` | Antwort — das, wonach gefragt wird |
| `R` | Bemerkung — wird neben Frage oder Lösung gezeigt, nie abgefragt |

Dasselbe Feld kann in der einen Richtung `Q` sein und in der anderen `A`. Genau das
macht eine Maske bidirektional: Bei einer Deutsch→Französisch-Maske sind in der einen
Richtung typischerweise die deutschen Felder `Q` und die französischen `A`, in der
anderen Richtung umgekehrt — so übt dieselbe Lern-Datei beide Richtungen, ohne zweimal
angelegt werden zu müssen.

## Lerneinheit: eine Karte

Eine **Lerneinheit** ist eine Karte: eine Kategorie plus ein Wert für jedes Feld dieser
Kategorie. Lerneinheiten sind fortlaufend nummeriert (1..N) in der Reihenfolge, in der
sie in der Lern-Datei stehen. Ein Wert kann reiner Text sein oder **formatierter Text**
— fett, kursiv, unterstrichen, farbig und markiert, gesetzt im
[Lerneinheiten-Editor](04-unit-editor.md).

## Lern-Datei und Maskendatei: warum es zwei gibt

Ihr Material liegt in zwei zusammengehörigen Dateien, ausführlich beschrieben in
[Erste Schritte](01-getting-started.md#die-drei-dateiarten):

- Die **Lern-Datei** (`.vok`) enthält Ihre Lerneinheiten sowie eine schreibgeschützte
  **Kopie** der Maske — eingefroren in der Form, die sie beim letzten Speichern der
  Lern-Datei hatte.
- Die **Maskendatei** (`.inf`) ist die eigene, *bearbeitbare* Heimat der Maske.

Die Lern-Datei trägt ihre eigene Kopie, damit sie immer korrekt öffnet, auch wenn die
`.inf`-Datei fehlt, umbenannt wurde oder ganz woanders liegt. Das bedeutet aber auch:
das Bearbeiten der `.inf` im [Mask Editor](05-mask-editor.md) ändert für sich genommen
noch keine Lern-Datei. Um die eingebettete Kopie einer Lern-Datei auf den neuesten Stand
zu bringen, verwenden Sie **Edit ▸ Andere Kopien dieser Maske aktualisieren...**,
beschrieben in
[Der Mask Editor](05-mask-editor.md#lern-dateien-synchron-halten).

Zwei Lern-Dateien, die sich dieselbe Maske teilen — zum Beispiel die Lektion dieser
Woche und die der vergangenen Woche — werden intern als zusammengehörig erkannt, auch
wenn jede ihre eigene eingefrorene Kopie behält. Genau das ermöglicht es **Andere
Kopien dieser Maske aktualisieren**, jede aus einer gegebenen `.inf` gebaute Lern-Datei
zu finden und zur Aktualisierung anzubieten, egal wo auf der Festplatte sie liegt.
