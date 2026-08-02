# Das Lexikon

Das **Lexikon** (**Lexikon**, `Alt+X` — eine direkte Aktion, kein Untermenü) sucht Text
über Lerneinheiten hinweg, in einem von zwei Bereichen.

## Speicher durchsuchen

Durchsucht die aktuell geladenen Lerneinheiten, gefiltert nach **Suchtext** und
optional einer einzelnen **Kategorie** (oder **Alle Kategorien**). Treffer zeigen, in
welchen Feldern der Text gefunden wurde.

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

Beide Suchmodi beachten die Optionen **Groß-/Kleinschreibung beachten** und
**Akzente beachten** aus den
[Erweiterten Lernoptionen](11-settings.md#lernoptionen) — dieselben Einstellungen, die
auch bestimmen, wie eine getippte Antwort während einer Sitzung bewertet wird.
