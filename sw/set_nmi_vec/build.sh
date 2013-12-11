#!/bin/sh

# build Peek & Poke
vc Peek.c -o Peek
vc Poke.c -o Poke

# build SetNMI
vasmm68k_mot -m68010 -Fhunkexe SetNMI.s -o SetNMI
chmod +x SetNMI

