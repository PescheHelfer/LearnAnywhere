# Einstellungen

Alles Konfigurierbare liegt im Menü **Optionen** (`Alt+O`), dazu der Stufennamen-Editor
aus [Stufenlernen](07-level-learning.md#stufen-benennen). Dieses Kapitel listet jede
Option und, am Ende, wo welche Art von Einstellung tatsächlich auf der Festplatte
gespeichert wird.

## Lernoptionen

**Optionen ▸ Erweiterte Lernoptionen** — jede Option hier wirkt sich ab der nächsten
Antwortprüfung aus; eine Änderung mitten in einer Sitzung wirkt sofort.

| Option | Standard | Wirkung |
|---|---|---|
| Falsche Eingabe korrigierbar | An | Bietet bei einer falschen Antwort "Eigentlich richtig" in der Bewertungszeile an |
| Vollständige Eingabe erforderlich | An | Jedes nicht leere Lösungsfeld muss für einen Treffer beantwortet werden |
| Groß-/Kleinschreibung beachten | An | Unterscheidet Groß-/Kleinschreibung beim Vergleich |
| Akzente beachten | An | Unterscheidet Akzente beim Vergleich |
| Beinahe-Treffer als „Fast“ akzeptieren | Aus | Schaltet das Ergebnis "Fast" frei |
| Ähnlichkeitsschwelle für „Fast“ (%) | 80 | Wie nah ein Beinahe-Treffer sein muss, um als "Fast" zu zählen |
| Uhr anzeigen | Aus | Zeigt die verstrichene Zeit während einer Sitzung |
| Zeitlimit (Sekunden) | 0 (kein Limit) | Begrenzt, wie lange eine Sitzung laufen darf |
| Mindestabfragen beachten | Aus | Siehe unten |
| Mindestabfragen | 2 | Wert für den obigen Schutz |
| Falsch-Antworten begrenzen | Aus | Siehe unten |
| Grenze für falsche Antworten | 10 | Wert für die obige Begrenzung |

Die Vergleichs-, Fast-Treffer- und Schutzoptionen werden vollständig in
[Wie Antworten bewertet werden](08-answer-evaluation.md) erklärt. Abfragerichtung,
Modus, Mischen, Beherrschungsschwelle und ob überhaupt getippt werden muss, werden
stattdessen auf dem
[Einrichtungsbildschirm](06-learning-sessions.md#eine-sitzung-einrichten) eingestellt,
da sie eine Sitzung beschreiben statt zu bestimmen, wie eine einzelne Antwort bewertet
wird.

## Darstellung und Sprache

**Optionen ▸ Darstellung** — **System**, **Hell**, **Dunkel**, **Dunkelblau** (die
Voreinstellung) oder **Hellblau**.

**Optionen ▸ Sprache** — **Englisch** (die Voreinstellung) oder **Deutsch**. Das
schaltet jede Beschriftung im Programm um, einschließlich der ALT-Tastenkürzel der
Menüs — der Buchstabe, der ein Menü auf Englisch öffnet, muss auf Deutsch nicht
derselbe sein — und dieses Handbuch selbst folgt derselben Einstellung.

## Statistik-Optionen

**Optionen ▸ Statistiken** enthält automatisches Laden, automatisches Speichern und
die Anzahl der aufbewahrten Sitzungsdateien, alle beschrieben in
[Arbeiten mit Dateien](03-managing-files.md#automatisch-laden-und-automatisch-speichern).
Alle drei betreffen allein die Sitzungsdateien. Die Allzeit-Statistik einer Lern-Datei
wird unabhängig von diesen Einstellungen geführt — siehe
[Die zwei Statistiken](09-statistics.md#die-zwei-statistiken).

## Wo Einstellungen liegen

Zwei getrennte Speicherorte, beide vollständig lokal — nichts hiervon wird jemals
irgendwohin gesendet:

- Ihre **Lernoptionen**, Stufennamen und zuletzt verwendeten Lern-Datei-/Maskenpfade
  werden in `learn_anywhere.settings.json` geschrieben, in einem Ordner `LearnAnywhere`
  am üblichen Speicherort für benutzerbezogene Konfiguration Ihres Betriebssystems
  (`%APPDATA%` unter Windows; `$XDG_CONFIG_HOME` oder `~/.config` unter Linux).
- **Darstellung, Sprache, zuletzt verwendete Ordner, die Schalter für automatisches
  Laden/Speichern sowie Größe und Position des Fensters** werden getrennt davon im
  eigenen Einstellungsspeicher des Betriebssystems abgelegt.

Keine der beiden Dateien muss von Hand angefasst werden — alles darin ist über die in
diesem Kapitel beschriebenen Menüs erreichbar —, aber beide sind reiner, lesbarer Text,
falls Sie doch einmal nachsehen möchten.
