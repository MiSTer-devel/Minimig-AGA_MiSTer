This is a special build of the DE1 version of Minimig.
It is based on the v2.0 release by Tobiflexx.

It adds mouse button and joystick emulation via PS/2 keboard.
Only the "default" mouse & joystick ports are supported.

The mappings are as follows:

<L-GUI>+<L-ALT>	Mouse Button 1
<R-GUI>+<R-ALT> Mouse Button 2

<ARROW-UP>	Joystick Up
<ARROW-DOWN>	Joystick Down
<ARROW-LEFT>	Joystick Left
<ARROW-RIGHT>	Joystick Right
<L-CTRL>	Joystick Fire
<L-ALT>		Joystick Fire 2

(note: GUI == Windows Key)

Notes:
------

This is an experimental release.

The above keys are also sent to the keyboard controller,
activating 'mouse' and 'joystick' switches do NOT suppress the
keyboard codes. This can cause problems with some games.

Activating Mouse Button 2 should NOT generate Joystick Fire 2
while <L-GUI> is depressed (I haven't tested this).

Ideally, there should be an OSD option added to enable/disable
the emulation. Enabling the emulation should also suppress the
corresponding key presses from the Amiga keyboard input.
It would also be nice to be able to swap/switch
the mouse and joystick ports using the OSD.

Testing:
--------
Hybris			OK
Battlezone		OK
SWIV			OK
Rolling Thunder		OK
IK+			OK
Silkworm		OK
Katakis			Problems w/control (keyboard conflicts?)

I can't vouch for the validity of the images that didn't work.

--
tcdev (mailto:msmcdoug@iinet.net.au)
