#!/usr/bin/env bash


RAILS_ENV=production bundle exec rake import:shipments 

echo script have done at `date`
