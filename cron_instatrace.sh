#!/bin/bash
echo "=================Start Importing=============="

source ~/.rvm/scripts/rvm
RAILS_ENV=production bundle exec rake import:shipments
RAILS_ENV=production bundle exec rake import:milestones

echo Importing have done at `date`
