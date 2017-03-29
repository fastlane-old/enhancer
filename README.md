<h3 align="center">
  <a href="https://github.com/fastlane/fastlane">
    <img src="app/assets/images/fastlane.png" width="150" />
    <br />
    fastlane
  </a>
</h3>

-------

enhancer
============

[![Twitter: @FastlaneTools](https://img.shields.io/badge/contact-@FastlaneTools-blue.svg?style=flat)](https://twitter.com/FastlaneTools)
[![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/fastlane/enhancer/blob/master/LICENSE)

[fastlane](https://fastlane.tools) tracks the number of errors for each action to detect integration issues.

### Privacy

This does **not** store any personal or sensitive data. Everything `enhancer` stores is the ratio between successful and failed action runs.

### Why?

- This data is very useful to find out which actions tend to cause the most build errors and improve them!
- The actions that are used by many developers should be improved in both implementation and documentation. It's great to know which actions are worth improving!

To sum up, all data is used to improve `fastlane` more efficiently

### Opt out

You can set the environment variable `FASTLANE_OPT_OUT_USAGE` to opt out.

Alternatively, add `opt_out_usage` to your `Fastfile`.

# Running _enhancer_ locally

* Start with a `bundle install` in the project directory to make sure you have all of the dependencies

## Set needed environment variables

* Create a `.env` file in your _enhancer_ project root containing the desired values for:

```
ANALYTIC_INGESTER_URL=[the public URL for the Analytic Ingester service - can be omitted!]
FL_PASSWORD=[password used to see the web dashboard]
```

## Getting a database snapshot

* Get PostgreSQL installed on your Mac
  * https://postgresapp.com/ is a quick way to get that going
* Make sure you are signed in to the Heroku command line application
  * https://devcenter.heroku.com/articles/heroku-cli
* Run `heroku pg:pull DATABASE_URL enhancer --app fastlane-enhancer` to pull the latest data from production into your local DB
  * This will fail if you already have a local database called `enhancer`. In that case, decide where you want to drop your local DB, and try it again.

## Get Redis installed and running

* Install with `brew install redis`
* Run `redis-server /Users/mfurtak/homebrew/etc/redis.conf` in a tab that you keep around, or run `brew services start redis` to have it start up whenever your Mac does

## Run the Rails and Resque processes

Heroku uses something called a `Procfile` to track multiple processes that you want have started up, and a gem called `foreman` knows how to run these things for you locally

* Run `bundle exec foreman start` to start up the `web` and `worker` processes

```
$ bundle exec foreman start
10:09:22 web.1    | started with pid 55133
10:09:22 worker.1 | started with pid 55134
10:09:24 web.1    | [2017-03-29 10:09:24] INFO  WEBrick 1.3.1
10:09:24 web.1    | [2017-03-29 10:09:24] INFO  ruby 2.3.0 (2015-12-25) [x86_64-darwin16]
10:09:24 web.1    | [2017-03-29 10:09:24] INFO  WEBrick::HTTPServer#start: pid=55133 port=5000
```

**Note that this runs the web server on port 5000, rather than the typical 3000 for Rails**

# Using _enhancer_

### Supported Parameters

Enhancer supports parameters to filter the shown actions. Any combination of parameters are supported.

#### only

Limits the actions that will be shown to the supplied list. It can be used either with a single value or multiple values:

- `?only=gym`: Only shows info for the `gym` action
- `?only[]=gym&only[]=testflight&only[]=...`: Only show info for the supplied actions `gym, testflight, ...`

#### weeks

Limits the data to data from the previous weeks, for example:

- `?weeks=4`: Only show data from the previous 4 weeks

#### ratio_above & ratio_below

Only shows actions that are above or below a certain error ratio. The error ratio is calculated by `number_of_errors / number_of_launches`.

- `?ratio_above=0.5`: Shows actions with an error ratio >= 0.5
- `?ratio_below=0.5&ratio_above=0.1`: Shows actions with an error ratio between 0.1 and 0.5

#### top

Show the top % of actions

- `?top=10`: Show the top 10% of actions for each table (by launches and by ratio)

#### Examples

`?top=50&weeks=1&only[]=ipa&only[]=gym`

This will show which of the actions `ipa` and `gym` was used more often in the past week, and which of those had a worse error ratio

`?weeks=4&ratio_above=0.25&ratio_below=0.75`

Shows a list of actions that had an error ratio between 0.25 and 0.75 in the past 4 weeks.

# Code of Conduct
Help us keep `fastlane` open and inclusive. Please read and follow our [Code of Conduct](https://github.com/fastlane/code-of-conduct).

# License
This project is licensed under the terms of the MIT license. See the LICENSE file.
