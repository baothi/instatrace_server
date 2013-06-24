#!/bin/bash
echo "=================Start Checking=============="

source ~/.rvm/scripts/rvm
#RAILS_ENV=production bundle exec rake monitor:check_milestone_damaged
cd /var/www/apps/instatrace/track_instatrace/current/
RAILS_ENV=production bundle exec rake monitor:check_milestone_damaged


echo Checking milestone damaged have done at `date`
