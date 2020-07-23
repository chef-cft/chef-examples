This script provides an example of using Ruby to make queries against the [Chef Automate API](https://automate.chef.io/docs/api/).

# Acquire an Automate Token

First off you will need an API token with full admin access. This is documented here: https://automate.chef.io/docs/api/#section/Authentication

`chef-automate iam token create admin_api --admin`

You may want to keep track of the token for later re-use.

# Export the Automate Token and URL

Export the `AUTOMATE_TOKEN` as an environmental variable:

`export AUTOMATE_TOKEN='YOURTOKEN'`

Export the `AUTOMATE_URL` as well:

`export AUTOMATE_URL='https://AUTOMATESERVER'`

# Usage

With the environmental variables set, the [checkins.rb](checkins.rb) script can be called directly with

```
$ ./checkins.rb
bender has checked in within the last hour
cubert has checked in within the last hour
flexo has checked in within the last hour
hermes has checked in within the last hour
-------------------------------------------------------------
2 hours: bender
2 hours: flexo
2 weeks: banjo
```

The point of the script is to segment out nodes by their check-in time, in batches of 1 hour, 2 hour, 1 week, 2 weeks, and 3 weeks. The point of the script was to provide an example of working with the API, there are commented out examples of getting "failed", "missing" or "successful" nodes that would require changing the URI. The output is simple `puts`, but the results are stored in arrays and could be pushed out as CSV or JSON if necessary with a few minor changes.
