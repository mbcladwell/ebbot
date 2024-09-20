#! /bin/bash
export LC_ALL="C"
export GUILE_LOAD_PATH=guileloadpath
export GUILE_LOAD_COMPILED_PATH=guileloadcompiledpath
cd $1
guileexecutable -L . -e '(ebbot)' -s ebbotstorepath/share/guile/site/3.0/ebbot.scm $1 $2

