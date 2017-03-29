web: bundle exec rails server -p $PORT
worker: env QUEUE=* TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7 bundle exec rake environment resque:work
