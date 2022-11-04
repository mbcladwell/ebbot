#! /bin/bash

export LC_ALL="C"
export GUILE_LOAD_PATH="/gnu/store/lxbvzmdcv82ik37z4np3c45p11iic7qx-guile-json-4.5.2/share/guile/site/3.0:/gnu/store/pa5y73jrcfgj9cmpvwiw1hv61sfbi8lj-artanis-0.5.3/share/guile/site/3.0:/gnu/store/3f0lv3m4vlzqc86750025arbskfrq05p-guile-dbi-2.1.8/share/guile/site/2.2:/gnu/store/695xgk69br87w3acm3pfhziyh1kx4xym-mysql-5.7.33${GUILE_LOAD_PATH:+:}$GUILE_LOAD_PATH"

export GUILE_DBD_PATH="/gnu/store/435chwsbpc8f388nw6dxi36d16ibn0bx-guile-dbd-mysql-2.1.8/lib"

rm -rf /home/mbc/data/jblo2cf0a6
##./init-acct.scm /home/mbc/data jblo /home/mbc/projects/bab/bab/creds.json
./init-acct.scm $1 $2 $3
