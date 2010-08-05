Sentry is basically a Nagios clone: it runs checks every so often, and notifies you if something fails, e.g. your server is down. I know there's a million of these services already but here's why Sentry is different:

* You can write your own checks, in Ruby. This allowed me to write a custom checker for Cohuman's incoming email service: once an hour, my Sentry sends an email to new@cohuman.com, then waits for the "I've created a task" confirmation email to appear in its IMAP inbox.

* Checks can run in the background via DelayedJob; they're in a pending state until they succeed or fail.

* Sentry runs on Heroku, so anyone can create their own instance for the cost of a worker (currently ~$36/mo, which is kind of steep, but might be worth it). (There's no reason it couldn't run on another server too.)

* It's a good example app for Sinatra, Heroku, Erector, Ruby email sending and checking, and TDD.

Check out the demo at http://sentry.heroku.com
