#! /bin/bash

TARHASH=$(guix hash "/home/mbc/projects/ebbot/ebbot-0.1.tar.gz")
sed -i "s/[a-z0-9 \"]*))));;anchor1/             \"$TARHASH\"))));;anchor1/" /home/mbc/projects/ebbot/guix.scm


cp /home/mbc/projects/ebbot/guix.scm /home/mbc/projects/labsolns/labsolns/ebbot.scm
cd /home/mbc/projects/labsolns/
git commit -a -S -m "autocommit"
git push
cd /home/mbc/projects/ebbot
gh release delete v0.1 -y
gh release create v0.1 /home/mbc/projects/ebbot/ebbot-0.1.tar.gz --generate-notes
