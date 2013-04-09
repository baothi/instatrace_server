#!/bin/bash
echo "=================Start Deletting=============="

source ~/.rvm/scripts/rvm
cd /var/www/apps/instatrace/track_instatrace/current/
RAILS_ENV=production bundle exec rake del:remove_old_files

echo Delete have done at `date`
