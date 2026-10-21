# Wie Antworten bewertet werden

Jede geprüfte Antwort erhält eines von drei Ergebnissen, und zu jedem Ergebnis bietet
eine Reihe von Bewertungsschaltflächen (`F5`/`F6`/`F7`) Ihnen das letzte Wort. Dieses
Kapitel behandelt beide Hälften: was das Programm von sich aus entscheidet, und was Sie
überschreiben können.

Alle hier erwähnten Optionen finden sich unter
**Optionen ▸ Erweiterte Lernoptionen** — die vollständige Liste und wo sie gespeichert
werden, siehe [Einstellungen](11-settings.md#lernoptionen).

## Ihre Antwort mit der Lösung abgleichen

Vor dem Vergleich werden sowohl Ihre Antwort als auch die Lösung **normalisiert**:

- Führende und abschließende Leerzeichen werden entfernt.
- Ist **Groß-/Kleinschreibung beachten** nicht eingeschaltet, werden beide
  kleingeschrieben.
- Ist **Akzente beachten** nicht eingeschaltet, werden Akzente entfernt (é → e,
  ü → u, und so weiter).

Ist **Vollständige Eingabe erforderlich** eingeschaltet (Standard), muss jedes Feld mit
nicht leerer Lösung ausgefüllt werden — fehlt in einer Antwort eines von mehreren
erforderlichen Feldern, gilt sie nicht als Treffer, auch wenn das Getippte korrekt ist.
Im [Stufenlernen](07-level-learning.md) füllt das Gerüst einen Teil jeder Antwort für
Sie aus, und diese Zeichen gelten als getippt — ein Gerüstfeld kommt also nie leer an,
unabhängig davon, wie diese Option eingestellt ist.

Felder mit derselben von Null verschiedenen
[Gleichheitsgruppe](02-concepts.md#gleichheitsgruppe) werden zusammen geprüft, Sie
dürfen ihre Werte also in beliebiger Reihenfolge tippen. Jeder getippte Wert wird mit
dem Lösungswert verglichen, dem er am besten entspricht, und mit genau diesem Wert
vergleicht ihn auch die Ähnlichkeit für **Fast**: Das Vertauschen zweier Zeilen macht
aus einem Beinahe-Treffer nie eine falsche Antwort.

In der **Korrektur** erscheint eine Gleichheitsgruppe in der Reihenfolge, in der Sie sie
getippt haben. Jede Zeile behält ihre Beschriftung und zeigt den Lösungswert, dem ihre
Eingabe zugeordnet wurde — nach einem Vertauschen mit einem Tippfehler ist also nur der
Tippfehler hervorgehoben. Die Ansicht **Lösung** zeigt immer die Reihenfolge der Lern-Datei.

## Die drei Ergebnisse

- **Richtig** — Ihre normalisierte Antwort stimmt genau mit der Lösung überein.
- **Fast** — nur möglich, wenn **Beinahe-Treffer als „Fast“ akzeptieren**
  eingeschaltet ist. Eine knappe, aber nicht exakte Antwort wird, sofern sie die
  **Ähnlichkeitsschwelle für „Fast“ (%)** erreicht oder überschreitet (standardmäßig
  80 %), als Beinahe-Treffer statt als klar falsch markiert.
- **Falsch** — alles andere.

Beim Anzeigen kann der Antwortbereich Ihre Antwort mit gegen die Lösung hervorgehobenen
Unterschieden zeigen (**Korrektur**), die reine **Lösung**, oder **Ihre Antwort**
unmarkiert — mit `F9` während einer Sitzung durchschalten; siehe
[Lernsitzungen](06-learning-sessions.md#whrend-einer-sitzung).

In der **Korrektur** verliert ein Antwortfeld mit mindestens einem Fehler die eigene
**Textfarbe**, **Markierung**, **Unterstrichen** und Durchstreichung der Einheit, damit
sie kein hervorgehobenes Zeichen verdecken und nicht mit den Zeichen für einen
fehlenden oder überzähligen Buchstaben verwechselt werden. **Fett** und **Kursiv**
bleiben. Ein Feld ohne Fehler, die Frage- und Bemerkungsfelder sowie die Ansicht
**Lösung** behalten ihre gesamte Formatierung.

## Den Versuch bewerten

Nach einer Prüfung lässt eine Reihe von bis zu drei Schaltflächen Sie das automatische
Ergebnis bestätigen oder überschreiben. Welche Schaltflächen erscheinen, hängt davon
ab, was passiert ist:

| Situation | Angebotene Schaltflächen |
|---|---|
| Keine getippte Antwort (Selbsteinschätzung) | **Gewusst** · **Nicht gewusst** · **Nicht zählen** |
| Ergebnis: Richtig | **Richtig** · **Eigentlich falsch** · **Nicht zählen** |
| Ergebnis: Fast | **Falsch** (vorausgewählt) · **Nah genug** · **Nicht zählen** |
| Ergebnis: Falsch | **Falsch** · **Eigentlich richtig**\* · **Nicht zählen** |

\* Wird nur angeboten, wenn **Falsche Eingabe korrigierbar** eingeschaltet ist —
schalten Sie es aus, wenn ein Tippfehler nie stillschweigend in einen richtigen Versuch
umgewandelt werden soll.

**Nah genug** verzeichnet den Versuch als richtig, genau wie das programmeigene
"Richtig". **Nicht zählen** verwirft den Versuch vollständig — weder gezählt noch
verzeichnet — nützlich für eine Karte, die Sie eindeutig aus Gründen falsch getippt
haben, die nichts damit zu tun haben, ob Sie die Antwort wussten.

## Schutzmechanismen

- **Mindestabfragen beachten** verhindert mit dem Wert **Mindestabfragen**, dass eine
  Einheit schon beim ersten Glückstreffer als gemeistert gilt — sie muss auch
  mindestens so oft abgefragt worden sein.
- **Falsch-Antworten begrenzen** stoppt mit dem Wert **Grenze für falsche Antworten**
  das weitere Hinzufügen zum Falsch-Zähler einer Einheit, sobald diese Anzahl erreicht
  ist — nützlich, wenn eine Handvoll früher Fehler nicht auf Dauer die langfristige
  Trefferquote dominieren soll.

Beide sind standardmäßig ausgeschaltet.
