#!/bin/bash
echo "=================Start Importing Descartes Milestone=============="

source ~/.rvm/scripts/rvm
#RAILS_ENV=production bundle exec rake import:run_descartes
cd /var/www/apps/instatrace/track_instatrace/current/
RAILS_ENV=production bundle exec rake import:run_descartes


echo Importing Descartes have done at `date`
