
Copy "spihost.rom" and "kick.rom" in the root folder on your SD-Card. .SOF and .POF are the bitstreamfiles to configure the DE1 Board. Please read the documentation from Terasic.
SW[9] Choose Monitor frequence,
SW[0] off-on => RESET,
SW[3..0] must swith on,
SW[8..4] unused,


To use Joystick, mice and keyboard simultan you need an adapter shown on the attached pictures.

Die Dateien spihost.rom und kick.rom müssen in das root-verzeichnis der SD-Karte kopiert werden. Mit pof und sof kennst du dich ja aus.
Mit den vier Tasten wird das Diskmenue gesteuert. Es werden Diskimages vom Typ .ADF erwartet.
To use Joystick, mice and keyboard simultan you need an adapter shown on the attached pictures.

SW[9]-Monitorumschaltung.
Sw[0] aus-an löst einen komplett Reset aus.
SW[3..0] müssen an sein - damit lassen sich einzelne Teile des Cores reseten.
SW[8..4] unused.

Debugausgaben kommen über die RS232 mit 11500 Baud und 8Bit.

Das KICK.ROM muß 512KB groß sein. KS 2.04 geht wie es ist und KS1.3 muß 2x hintereinander in ein File.

Viele Grüße
Tobias
