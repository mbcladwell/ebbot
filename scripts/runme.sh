#! /bin/bash
export LC_ALL="C"
export GUILE_LOAD_PATH="/home/mbc/projects/ebbot${GUILE_LOAD_PATH:+:}$GUILE_LOAD_PATH"
./clean.sh
guix package --install-from-file=guix.scm
##/gnu/store/1jgcbdzx2ss6xv59w55g3kr3x4935dfb-guile-3.0.8/bin/guile -e '(ebbot)' -s /home/mbc/projects/ebbot/ebbot.scm /home/mbc/data/jblo2cf0a6/ 260
/gnu/store/1jgcbdzx2ss6xv59w55g3kr3x4935dfb-guile-3.0.8/bin/guile -L . -e '(ebbot)' -s ebbot.scm /home/mbc/data/jblo2cf0a6/ 260
