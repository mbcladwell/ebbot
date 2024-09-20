#! /bin/bash
export GUILE_LOAD_PATH=guileloadpath
export GUILE_LOAD_COMPILED_PATH=guileloadcompiledpath
guileexecutable -L . -e '(ebbot mastsoc)' -s $HOMEebbotstorepath/share/guile/site/3.0/ebbot/mastodon.scm

