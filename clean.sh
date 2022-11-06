#!/bin/bash
rm ./ChangeLog
rm -Rf  ./build-aux
rm ./configure.ac
rm ./Makefile.am
rm ./pre-inst-env.in
rm ./guix.scm
rm ./hall.scm
rm ./*.go
rm ./ebbot/*.go
rm ./ebbot-0.1.tar.gz
rm ./scripts/*.*
hall init --convert --author "mbc" ebbot --execute
hall scan -x
hall build -x
cp /home/mbc/syncd/tobedeleted/ebbot/guix.scm .
cp /home/mbc/syncd/tobedeleted/ebbot/hall.scm .
cp /home/mbc/syncd/tobedeleted/ebbot/Makefile.am .
cp /home/mbc/syncd/tobedeleted/ebbot/ebbot.sh ./scripts
cp /home/mbc/syncd/tobedeleted/ebbot/format.sh ./scripts
cp /home/mbc/syncd/tobedeleted/ebbot/init-acct.sh ./scripts
autoreconf -vif && ./configure && make

make dist

guix hash ./ebbot-0.1.tar.gz
## cp /home/mbc/syncd/tobedeleted/ebbot/guix.scm  /home/mbc/projects/labsolns/labsolns/ebbot.scm

##scp -i /home/mbc/labsolns.pem ./shinyln-0.1.tar.gz admin@ec2-18-189-31-114.us-east-2.compute.amazonaws.com:.
##scp -i /home/mbc/labsolns.pem /home/mbc/syncd/tobedeleted/shinyln/guix.scm admin@ec2-18-189-31-114.us-east-2.compute.amazonaws.com:.
##guix package --install-from-file=guix.scm
##source /home/mbc/.guix-profile/etc/profile
