#!/bin/sh

# build Peek
vc Peek.c -o Peek

# build SetNMI
vasmm68k_mot -m68010 -Fhunkexe SetNMI.s -o SetNMI

