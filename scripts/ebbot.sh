#! /bin/bash
export LC_ALL="C"
export GUILE_LOAD_PATH="$HOME/abcdefgh/share/guile/site/3.0${GUILE_LOAD_PATH:+:}$GUILE_LOAD_PATH"
guile -e main -s ebbot.scm $1 $2

