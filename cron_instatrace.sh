#!/bin/bash
echo "=================Start Importing=============="

source ~/.rvm/scripts/rvm
#RAILS_ENV=production bundle exec rake import:shipments
cd /var/www/apps/instatrace/track_instatrace/current/
RAILS_ENV=production bundle exec rake import:run_all


echo Importing have done at `date`
