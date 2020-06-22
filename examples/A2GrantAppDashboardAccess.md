# HowTo - Grant Access to the Applications Dashboard in Automate 2

These steps will grant blanket access to the Applications view in Automate 2 for all users.

## Before You Start

### Assumptions

* Chef Automate 2 Installed
* curl installed and running locally.

### Tested Versions

* Chef Automate 2 | [`20200603114954`]

## Grant Access to the Applications Dashboard in Automate 2

1. Create JSON policy definition in a text file (in this example, we'll call it `policy`): 
```
{
  "name": "Applications Viewer",
  "id": "applications-viewer-access",
  "members": [
    "*"
  ],
  "statements": [
    {
      "effect": "ALLOW",
      "actions": [
        "applications:*"
      ],
      "projects": [
        "*"
      ]
    }
  ]
}
```
2. POST the policy. I used an admin token, but any token that can manage IAM policies should work:
```
export TOKEN=`chef-automate iam token create admoon --admin`
curl -X POST https://localhost/apis/iam/v2/policies --data-binary @./policy -k -H "api-token: $TOKEN"  -v
```
3. Double check in the interface to ensure that all members been added. In the GUI: Settings -> Policies -> {Name of your policy, my example is “applications-viewer-access} -> Members
4. If you need to edit membership, this can be done through the UI or set using the 'members' JSON Object.