#!/bin/sh -e

cd /home/bugzilla
export PERL5LIB=/home/bugzilla/lib

sleep 30

perl checksetup.pl /tmp/checksetup_answers.txt
perl checksetup.pl /tmp/checksetup_answers.txt
perl checksetup.pl

/usr/bin/supervisord -c /etc/supervisord.conf
