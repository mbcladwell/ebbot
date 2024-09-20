#! /bin/bash
export GUILE_LOAD_PATH="/home/mbc/projects/ebbot:gnu/store/0888y04n94lwlkpyhdbflqlsps8pqs9m-guile-gnutls-4.0.0/share/guile/site/3.0:/gnu/store/nxr3f2n06sbf94kv1mwcdgxj76qlka7y-guile-oauth-0.1.3/share/guile/site/3.0${GUILE_LOAD_PATH:+:}$GUILE_LOAD_PATH"
guile -e '(ebbot)' -s /home/mbc/projects/ebbot/ebbot.scm /home/mbc/data/bernays/ 260
