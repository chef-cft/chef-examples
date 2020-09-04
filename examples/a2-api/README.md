These 2 scripts provide examples of using Ruby to make queries against the [Chef Automate API](https://automate.chef.io/docs/api/). The [checkins.rb](checkins.rb) script provides lists of nodes by their check-in times. The [node_count.rb](node_count.rb) gives the number of nodes that have checked in, are missing, and have failed broken down by Chef Infra Servers and Organizations. [audit_reports.rb](audit_reports.rb) provides the last compliance reports for a configurable number of days with the option of removing columns from the CSV output.

# Configuration

## Acquire an Automate Token

First off you will need an API token with full admin access. This is documented here: https://automate.chef.io/docs/api/#section/Authentication

`chef-automate iam token create admin_api --admin`

You may want to keep track of the token for later re-use.

## Export the Automate Token and URL

Export the `AUTOMATE_TOKEN` as an environmental variable:

`export AUTOMATE_TOKEN='YOURTOKEN'`

Export the `AUTOMATE_URL` as well:

`export AUTOMATE_URL='https://AUTOMATESERVER'`

# checkins.rb

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

# node_count.rb

The [node_count.rb](node_count.rb) script lists the current number of nodes that have checked in, succeeded, failed, and been marked missing nodes. It breaks them down by Chef Infra Servers and Organizations.

```
$ ./node_count.rb
chef-server, organization, total, succeeded, failed, missing
api.chef.io, matt, 1, 1, 0, 0
localhost, chef_solo, 1, 0, 0, 1
ndnd.bottlebru.sh, chef_managed_org, 11, 9, 1, 1
```

If you prefer JSON output:
```
$ ./node_count.rb json
{
  "ndnd.bottlebru.sh": {
    "chef_managed_org": {
      "total": 11,
      "successful": 9,
      "failed": 1,
      "missing": 1
    }
  },
  "localhost": {
    "chef_solo": {
      "total": 1,
      "successful": 0,
      "failed": 0,
      "missing": 1
    }
  },
  "api.chef.io": {
    "matt": {
      "total": 1,
      "successful": 1,
      "failed": 0,
      "missing": 0
    }
  }
}
```

# audit_reports.rb

The [audit_reports.rb](audit_reports.rb) script provides the export of https://docs.chef.io/automate/api/#operation/Export the last compliance report for nodes, configurable by the number of days and with the option of removing columns from the CSV output.

Last 3 days of JSON
```
$ ./audit_reports.rb 3 > output.json
```

If you prefer CSV, you may add additional filtering by passing the quoted columns to remove.
```
$ ./audit_reports.rb 1 csv "End Time" "Platform Name" "Platform Release" "Environment" FQDN "Profile Summary" "Control Title" "Control Impact" "Waived (true/false)" "Result Run Time" > output.csv
```
