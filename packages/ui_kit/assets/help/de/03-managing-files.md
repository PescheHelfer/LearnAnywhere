# Arbeiten mit Dateien

Alles Dateibezogene liegt im Menü **Datei** (`Alt+D`). Dieses Kapitel geht der Reihe
nach jeden Befehl darin durch, dazu die beiden automatischen Abläufe — Statistiken
automatisch laden und automatisch speichern —, die einen Teil davon leise für Sie
erledigen.

## Lerneinheiten

- **Lerneinheiten laden...** öffnet eine `.vok`-Datei und ersetzt dabei alles, was
  gerade im Speicher ist.
- **Lerneinheiten hinzuladen...** fügt die Einheiten einer weiteren Lern-Datei an das
  Ende der bereits geöffneten an, statt sie zu ersetzen. Die hinzugeladene Datei muss
  dieselbe Maske verwenden; tut sie das nicht, oder würde das Angleichen an die aktuelle
  Maske Daten verlieren, wird das Hinzuladen verweigert, statt eine der beiden Dateien
  stillschweigend zu beschädigen.
- **Neue Version der Lerneinheiten übernehmen...** übernimmt eine neue Version der
  geöffneten Lern-Datei — Tippfehler behoben, Einheiten ergänzt — und behält dabei Ihre
  eigenen Kennzeichnungen als schwierig. Siehe
  [Eine Lern-Datei teilen](#eine-lern-datei-teilen).
- **Lerneinheiten speichern** schreibt in die geöffnete Datei zurück.
  **Lerneinheiten speichern unter...** schreibt in einen neuen Pfad und wechselt dorthin,
  die ursprüngliche Datei bleibt unangetastet.
- **Lerneinheiten im Speicher löschen...** leert den Arbeitsbereich. Nach der
  Bestätigung wählen Sie zwischen dem Laden einer vorhandenen Maskendatei für den
  Neuanfang oder dem Erstellen einer brandneuen Maske — Letzteres führt direkt in den
  [Mask Editor](05-mask-editor.md), um sie zu gestalten. Dieser Befehl rührt nichts auf
  der Festplatte an; er leert nur, was gerade geladen ist.

## Masken

- **Neue Masken-Datei laden...** lädt eine `.inf`-Datei als die mit der aktuellen
  Lern-Datei verknüpfte Maske. Dabei werden die derzeit geladenen Lerneinheiten
  geleert, da eine Maske die Form vorgibt, in die diese Einheiten passen müssen.
- **Masken-Datei speichern** / **Masken-Datei speichern unter...** schreiben die
  gerade bearbeitete Maske in ihre `.inf`-Datei. Es sind dieselben Befehle, die auch
  die OK-Schaltfläche des [Mask Editors](05-mask-editor.md) selbst verwendet.

Ist mit einer Lern-Datei noch keine Maskendatei verknüpft — etwa weil sie aus einer
spontan erstellten Maske gebaut wurde — bietet der Mask Editor beim Öffnen an, aus der
eingebetteten Kopie der Lern-Datei eine solche zu erstellen, damit künftige Änderungen
irgendwo gespeichert werden können.

## Statistik

- **Statistik laden...** / **Statistik speichern** / **Statistik speichern unter...**
  laden oder schreiben eine `.sta`-Datei für die aktuelle Lern-Datei.
- **Aktuelle Statistik löschen...** löscht nach Bestätigung jeden verzeichneten Versuch
  für die aktuelle Lern-Datei. Das lässt sich nicht rückgängig machen. Ist das
  automatische Speichern eingeschaltet, wird die Sitzung, die Sie löschen, vorher in ihre
  Datei geschrieben und bleibt so erhalten; die nächste Sitzung legt eine eigene neue
  Sitzungsdatei an, statt sie zu überschreiben.

Diese vier Befehle finden sich auch auf dem Bildschirm [Statistik](09-statistics.md)
selbst wieder, sodass Sie ihn zum Sichern Ihrer Ergebnisse nie verlassen müssen. Sie
alle wirken auf die Arbeitsstatistik; die Allzeit-Statistik der Lern-Datei ist eine
zweite Datei, die automatisch geführt wird — siehe
[Die zwei Statistiken](09-statistics.md#die-zwei-statistiken).

Beide Arten von Statistikdatei liegen in einem Ordner namens `statistics` neben der
Lern-Datei: für `Franz/meinedatei.vok` ist das `Franz/statistics/`. Der Name ist immer
derselbe — klein geschrieben, nie übersetzt —, damit ein Ordner, den sich Windows und
Linux oder eine deutsch- und eine englischsprachige Person teilen, für alle derselbe
ist. Das Programm legt ihn an, sobald es zum ersten Mal eine Statistikdatei dorthin
schreibt; das Öffnen oder Durchsuchen einer Lern-Datei legt ihn nie an.

**Gelesen wird nur der Ordner `statistics`.** Eine `.sta`-Datei, die direkt neben der
Lern-Datei liegt, wo Versionen vor 1.2.0 sie geschrieben haben, wird nicht gefunden:
Das automatische Laden bietet sie nicht an, die Lern-Datei erscheint als **noch nicht
gelernt**, und die Allzeit-Statistik beginnt im Ordner `statistics` wieder bei null.
Wollen Sie solche Dateien behalten, verschieben Sie sie in den Ordner `statistics` neben
ihrer Lern-Datei, bevor Sie sie das nächste Mal üben.

## Wenn die Lern-Datei anderswo bearbeitet wurde

Die Statistik wird je Einheit verzeichnet. Eine Lern-Datei, die sich nach dem Schreiben
ihrer `.sta` geändert hat — in einer anderen Kopie des Programms bearbeitet, vom
Konverter neu erzeugt, auf dem Telefon neu importiert —, könnte deshalb leicht die
falschen Zähler den falschen Einheiten zuordnen.

Das tut sie nicht. Jede `.sta` speichert neben den Zählern einen Fingerabdruck jeder
Einheit, gebildet aus deren Frage- und Antwortfeldern. Beim Laden der Statistik folgt
jeder Zähler seinem Fingerabdruck dorthin, wo die Einheit jetzt steht; umgestellte,
eingefügte oder gelöschte Einheiten lassen die Geschichte des übrigen Bestands also
genau dort, wo sie hingehört. Bemerkungsfelder bleiben bewusst außen vor: eine
umgeschriebene Bemerkung kostet eine Einheit nie ihre Ergebnisse.

Zwei Änderungen setzen Ergebnisse bewusst zurück:

- Wird der **Frage- oder Antworttext** einer Einheit geändert, ist es eine andere
  Einheit — sie beginnt bei null, alle übrigen bleiben unberührt.
- Wird die **Rolle eines Feldes** in der [Maske](05-mask-editor.md) geändert, erhalten
  alle Einheiten einen neuen Fingerabdruck, die ganze Lern-Datei beginnt also bei null.

Ging nichts verloren — der Normalfall —, sagt das Laden dazu nichts. Gingen Ergebnisse
verloren, meldet die Statuszeile, wie viele Einheiten es betrifft, zum Beispiel **Die
Statistik von 3 Einheiten wurde zurückgesetzt — diese Einheiten haben sich geändert.**
Eine `.sta`, die vor Einführung der Fingerabdrücke geschrieben wurde, hat keine und wird
wie eh und je nach Position geladen.

Die **Lern-Datei selbst** außerhalb des Programms umzubenennen oder zu verschieben, ist
eine andere Sache. Jede Statistikdatei wird über den Namen der Lern-Datei gefunden, im
Ordner `statistics` daneben — `meinedatei_alltime.sta` und
`meinedatei_20250114_183000.sta` gehören zu `meinedatei.vok` und zu nichts sonst.
Benennen Sie die Lern-Datei im Dateimanager um oder verschieben Sie sie und lassen die
Statistikdateien zurück, sind diese verwaist: Das Programm findet keine davon, es gibt
also nichts automatisch zu laden, und die Allzeit-Statistik beginnt wieder bei null.
Gelöscht wird nichts, und endgültig verloren ist auch nichts — benennen Sie die
Statistikdateien passend zum neuen Namen der Lern-Datei um und lassen Sie sie im Ordner
`statistics` daneben, ist die Verbindung wiederhergestellt. Die Lern-Datei aus dem
Programm heraus unter neuem Namen zu speichern ist nicht dasselbe: Die
Allzeit-Statistik folgt der Lern-Datei in den Ordner `statistics` an ihrem neuen Ort —
es sei denn, dort liegt bereits eine. Diese gehört zu einer anderen Lern-Datei und wird nie
überschrieben; die Statuszeile sagt es.

## Eine Lern-Datei teilen

Lernen zwei Personen mit derselben Lern-Datei, behält jede Kopie der `.vok` ihre eigenen
[Kennzeichnungen als schwierig](06-learning-sessions.md#eine-einheit-als-schwierig-kennzeichnen).
Die Kennzeichnungen stehen in der Lern-Datei selbst: Die in Ihrer Kopie sind Ihre, die
in der Kopie einer anderen Person sind deren.

Das zählt, wenn eine **neue Version** der Lern-Datei verteilt wird — ein Tippfehler
behoben, ein paar Einheiten ergänzt. Kopieren Sie die neue Datei im Dateimanager über
Ihre, erhalten Sie die Kennzeichnungen aus der fremden Kopie statt Ihrer eigenen, und
Ihre manuellen Kennzeichnungen sind endgültig verloren. Öffnen Sie stattdessen Ihre
eigene Kopie, wählen Sie **Datei ▸ Neue Version der Lerneinheiten übernehmen...** und
dann die neue Datei:

- Ihre Lern-Datei übernimmt die Einheiten der neuen Version in deren Reihenfolge und
  behält ihren eigenen Dateinamen und ihre Statistikdateien. Die Statistik folgt jeder
  Einheit, wie unter
  [Wenn die Lern-Datei anderswo bearbeitet wurde](#wenn-die-lern-datei-anderswo-bearbeitet-wurde)
  beschrieben.
- Ihre Kennzeichnungen wandern zu denselben Einheiten der neuen Version, jede
  Abfragerichtung für sich, auch wenn Einheiten eingefügt oder umgestellt wurden. Eine
  Einheit, deren Frage oder Antwort nur leicht korrigiert wurde, behält ihre
  Kennzeichnungen ebenfalls — als geänderter Text beginnt ihre Statistik allerdings bei
  null.
- Die Kennzeichnungen aus der fremden Kopie werden nicht beachtet, und Einheiten, die
  in dieser Version neu sind, beginnen ohne Kennzeichnung. Erkannt wird dabei nichts:
  Über sie entscheiden Ihr eigenes Kennzeichnen und die nächste automatische Erkennung.
- Die neue Datei wird nur gelesen, nie verändert; Sie können sie also unverändert
  weitergeben.

Danach meldet die Statuszeile das Ergebnis, zum Beispiel **„words.vok“ auf die neue
Version gebracht: 3 Kennzeichnungen übernommen, 1 entfallen, weil ihre Einheit nicht
mehr existiert.** Jede manuelle oder automatische Kennzeichnung zählt je
Abfragerichtung einmal.

Eine Datei mit einer anderen Maske wird verweigert — sie ist keine Version dieser
Lern-Datei —, ebenso eine, die sich nur unter Datenverlust auf die neuere
Masken-Revision bringen ließe; die Meldung nennt dann, was verloren ginge, wie beim
Abgleich der Masken-Kopien. Eine Lern-Datei, die noch nie gespeichert wurde, hat
keine Datei, die sich aktualisieren ließe: Speichern Sie sie zuerst.

## Automatisch laden und automatisch speichern

Zwei unabhängige Schalter unter **Optionen ▸ Statistiken** ersparen Ihnen den Weg über
das Menü Datei:

- **Statistiken automatisch laden** — beim Öffnen einer Lern-Datei sucht das Programm
  in ihrem Ordner `statistics` nach einer passenden Sitzungsdatei mit Zeitstempel und
  fragt, falls es eine
  findet, ob sie geladen werden soll. Nichts wird stillschweigend geladen; Sie sehen
  vor der Entscheidung immer, wie alt die Datei ist und wie viel der Lern-Datei sie
  abdeckt.
- **Statistiken automatisch speichern** — startet eine Lernsitzung und ist der
  Lern-Datei noch keine Statistikdatei zugeordnet, wird automatisch eine angelegt,
  benannt nach der Lern-Datei und dem Moment des Sitzungsbeginns, im Ordner
  `statistics` der Lern-Datei, der dabei angelegt wird, falls es ihn noch nicht gibt.
  Von da an wird Ihr Fortschritt fortlaufend hineingeschrieben, ohne weitere
  Rückfrage.

**Nur die letzten N Sitzungsdateien behalten...** (ebenfalls unter
**Optionen ▸ Statistiken**) begrenzt, wie viele dieser automatisch gespeicherten
Dateien sich pro Lern-Datei ansammeln: sobald mehr als die eingestellte Anzahl
vorhanden sind, werden nach jeder neu geschriebenen die ältesten im Ordner
`statistics` der Lern-Datei gelöscht. Auf 0
gesetzt, werden alle Dateien behalten.

## Beenden

**Beenden...** fragt nach Bestätigung und speichert dann — falls automatisches
Speichern eingeschaltet ist — die Statistik ein letztes Mal, bevor das Programm
schließt. Die Schließen-Schaltfläche des Fensters (das X in der Titelleiste) durchläuft
genau denselben Ablauf, sodass sich die Ergebnisse einer Sitzung nicht dadurch
verlieren lassen, dass das Fenster statt des Menüs geschlossen wird.
