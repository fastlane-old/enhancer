web: bundle exec rails server -p $PORT
anaingworker: env QUEUE=analytic_ingester TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7 bundle exec rake environment resque:work
baconworker: env QUEUE=bacon_updater TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7 bundle exec rake environment resque:work
