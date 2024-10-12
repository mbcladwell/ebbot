#! /bin/bash
export LC_ALL="C"
export GUILE_LOAD_PATH=guileloadpath
export GUILE_LOAD_COMPILED_PATH=guileloadcompiledpath
guileexecutable -L . -e '(ebbot twitter)' -s /home/admin/ebbotstorepath/share/guile/site/3.0/ebbot/twitter.scm $1

