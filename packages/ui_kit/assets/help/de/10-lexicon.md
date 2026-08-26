# Das Lexikon

Das **Lexikon** (**Lexikon**, `Alt+X` — eine direkte Aktion, kein Untermenü) sucht Text
über Lerneinheiten hinweg, in einem von zwei Bereichen.

## Speicher durchsuchen

Durchsucht die aktuell geladenen Lerneinheiten, gefiltert nach **Suchtext** und
optional einer einzelnen **Kategorie** (oder **Alle Kategorien**). Treffer zeigen, in
welchen Feldern der Text gefunden wurde.

Ein leerer **Suchtext** (oder einer, der nur aus Leerzeichen besteht) bedeutet „alles“:
Es werden sämtliche Lerneinheiten aufgelistet. Zusammen mit einer **Kategorie** ist das
der Weg, eine einzelne Kategorie einer Lern-Datei durchzusehen — Kategorie wählen, Feld
leer lassen, suchen. Solche Treffer nennen keine Trefferfelder, denn es wurde nach
keinem Text gesucht.

## Dateien durchsuchen

Durchsucht jede `.vok`-Datei unterhalb eines gewählten Ordners, rekursiv — nicht nur die
gerade geöffnete Lern-Datei. Das ist gedacht für den Fall, dass Sie wissen, dass Sie
eine Karte irgendwann geschrieben haben, sich aber nicht erinnern, in welcher Lern-Datei
sie gelandet ist.

Treffer tragen sowohl eine **Quelldatei** als auch die **Trefferfelder**, sodass sich
Lern-Dateien unterscheiden lassen, wenn derselbe Text in mehr als einer auftaucht. Zwei
Modi bestimmen, was mit dem Gefundenen geschieht:

- **Nur anzeigen** — die Voreinstellung. Treffer werden angezeigt; am Speicher ändert
  sich nichts.
- **Gefundene Einheiten laden** — ersetzt die aktuell geladenen Einheiten nach
  Bestätigung durch die Treffer (dabei geht verloren, was im Speicher war). Dies wird
  rundweg verweigert, statt ein Durcheinander zu riskieren, wenn die Treffer zu mehr
  als einer Maske gehören, oder wenn das Angleichen an die neueste unter ihnen
  vertretene Maskenrevision Daten verlieren würde.

Sind Treffer geladen, bringt **Treffer laden** sie genauso in den Speicher, wie es das
Laden einer Lern-Datei tun würde.

Beide Suchmodi hören bei 2000 Treffern auf, damit eine sehr weite Suche über einen
großen Ordner das Programm nicht minutenlang eine Tabelle aufbauen lässt. In diesem Fall
steht über der Tabelle statt der gewohnten Anzahl **Ergebnisse: die ersten 2000 werden
angezeigt — es gibt weitere. Bitte Suche eingrenzen.** — eine gekappte Suche wird also
nie so gemeldet, als wäre nichts gefunden worden. Grenzen Sie sie mit einer
**Kategorie** oder mit Suchtext ein.

Beide Suchmodi beachten die Optionen **Groß-/Kleinschreibung beachten** und
**Akzente beachten** aus den
[Erweiterten Lernoptionen](11-settings.md#lernoptionen) — dieselben Einstellungen, die
auch bestimmen, wie eine getippte Antwort während einer Sitzung bewertet wird.
