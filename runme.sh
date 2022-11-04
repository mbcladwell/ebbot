#! /bin/bash
export LC_ALL="C"
export GUILE_LOAD_PATH="/home/mbc/projects/ebbot${GUILE_LOAD_PATH:+:}$GUILE_LOAD_PATH"
##export GUILE_LOAD_COMPILED_PATH=guileloadcompiledpath
/gnu/store/1jgcbdzx2ss6xv59w55g3kr3x4935dfb-guile-3.0.8/bin/guile -e '(ebbot)' -s /home/mbc/projects/ebbot/ebbot.scm $1 $2

