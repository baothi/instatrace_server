#!/bin/bash
echo "=================Start Checking=============="

source ~/.rvm/scripts/rvm
#RAILS_ENV=production bundle exec rake monitor:check_shipment_created
cd /var/www/apps/instatrace/track_instatrace/current/
RAILS_ENV=production bundle exec rake monitor:check_shipment_created


echo Checking post shipment have done at `date`
