#! /bin/bash
export GUILE_LOAD_PATH=guileloadpath
export GUILE_LOAD_COMPILED_PATH=guileloadcompiledpath
guileexecutable -e '(ebbot initacct)' -s ebbotstorepath/share/guile/site/3.0/ebbot/initacct.scm $1 $2 $3
