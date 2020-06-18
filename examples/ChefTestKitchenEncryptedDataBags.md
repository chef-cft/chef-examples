# How to use Encrypted Data Bags with Test Kitchen

This is a brief guide with a Test Kitchen example on how to create and use
Encrypted Data Bags with Test Kitchen.

## Before You Start

### Assumptions

* This was done on a Mac, some of the commands will be different if running from
a Windows or Linux machine.
* You have a basic understanding of Encrypted Data Bags, learn more here: 
https://docs.chef.io/data_bags/#encrypt-a-data-bag-item.

### Tested Versions

* Chef Workstation | [`20.6.x`] (should be fine with any version of Chef 
Workstation)

## Step 1 - Create local Chef Zero Repo and Update Workstation Config
If you already have a local repo, you can skip this step, if you don't, or are
scratching your head as to what that is, then follow these steps.

1. For Windows/Mac/Linux: perform the following commands from a Terminal or
Powershell prompt:
    ```
    # Note, "/" characters should work in modern Windows versions, 
    # however you may need to substitute "/" with "\" in the following 
    # commands for Windows
    cd ~/.chef
    # Generate a local repo
    chef generate repo chef-zero-repo
    cd ./chef-zero-repo/data_bags
    # Perform the following command to create a "data bag"
    mkdir credentials
    ```
1. You've just created a "data bag" on your local repo with no items in it.
1. Note, any time you want to create a local data bag, you first need to create
the directory with the same name as the data bag in your 
`~/.chef/chef-zero-repo/data_bags` directory, otherwise, your data bag will fail
to create.
1. Next, let's open our `~/.chef/config.rb` file and add the following line to 
the end:
    ```
    # For Mac/Linux
    chef_repo_path           "#{ENV['HOME']}/.chef/chef-zero-repo/"

    # For Windows
    chef_repo_path           "#{ENV['HOME']}\\.chef\\chef-zero-repo\\"
    ```
    This will tell Chef Workstation to use the newly created repo for storing
    local mode artifacts.

## Step 2 - Create your Encrypted Data Bag Secret
We're going to create a data bag called "credentials" and we're going to put
some secrets in it.

1. From inside your cookbook root, create the following directories if they 
don't exist (note `credentials` is the name of our data bag we're testing with,
just repeat this step with `<your data bag name>` when doing this for real):
    ```
    test
    └── fixtures
        └── data_bags
            └── credentials
    ```
1. In the above, `data_bags` is the path that will be referenced in Test Kitchen
for all data bags used. `credentials` represents the `data bag` that will be 
used.
1. Next, create a file called `hab.json`, in it we're going to store some fake
Habitat credentials, add this to the file and save it:
    ```json
    {
        "id": "hab",
        "hab_token": "<paste-some-secret-text>"
    }
    ```
1. Now we're going to generate an encryption key, and we're going to save it to
a file. We'll use `openssl` to do this, I recommend using Chocolatey for Windows
to install (`choco install openssl`), and Homebrew for Mac (`brew install
 openssl`), it's usually already installed in Linux. Once you have the OpenSSL 
binary installed, run the following command to generate a Chef compatible key 
(from within the root of your cookbook directory) _Note, this is the command for
Mac, please make a PR with the correct syntax for Windows if you want to 
contribute :)_ :
    ```
    openssl rand -base64 512 | tr -d '\r\n' > ./test/fixtures encrypted_data_bag_secret
    ```

## Step 3 - Create your Encrypted Data Bag
1. Next, we'll create the Encrypted Data Bag using `--local-mode`, from the root
of the cookbook directory, run the following command:
    ```
    knife data bag from file credentials hab.json --local-mode --secret-file ./test/fixtures/encrypted_data_bag_secret
    ```
1. What just happened? Chef Infra Client ran in local mode, and created an
encrypted version of `hab.json` in your local Chef Zero Repo, in 
`~/.chef/chef-zero-repo/data_bags/credentials/hab.json` with the
encrypted contents of the `hab.json` you created in step 1.3. Let's view the
contents of the local data bag, notice the token istelf is encrypted:
    ```
    knife data bag show credentials hab --local-mode

    ## Output

    WARNING: Encrypted data bag detected, but no secret provided for decoding. Displaying encrypted data.
    hab_token:
    auth_tag:       iQYf4lfpYDPDwzN5XJEB6w==

    cipher:         aes-256-gcm
    encrypted_data: B4FhSguF2KWd+KxxF7onIfjskowR5E6FtWBPFG8DpvowdJSOZAtDnOKLs
    tI+/43pnhp4MlyoG1QJ4E9LjWF2hop1VdWO7cQfm9QAY81MMlFW6DYGKOhSy
    4R2Gt8EYMY6l/FPU

    iv:             TWRzBXSSLiyoexJl

    version:        3
    id:             hab
    ```
1. To view the decrypted data bag, you would run the following command:
    ```json
    knife data bag show credentials hab --local-mode --secret-file test/fixtures/encrypted_data_bag_secret -F json

    ## Output

    Encrypted data bag detected, decrypting with provided secret.
    {
        "id": "hab",
        "hab_token": "_Qk9YLxxxxxxxxxxxxueTFKQg=="
    }
    ```
1. You can now safely delete your `hab.json` file, or move it somewhere out of
the cookbook directory so it's not accidentally committed to SCM.

## Step 4 - Put it all together in Test Kitchen
Now that we've created an encrypted data bag in local mode, we need to make it
work with Test Kitchen.

1. First, we need to copy the `hab.json` data bag item over to the local 
cookbook, we'll do that by running this command from the cookbook root:
    ```
    cp ~/.chef/chef-zero-repo/data_bags/credentials/hab.json ./test/fixtures/data_bags/credentials/
    ```
1. Next, edit your `kitchen.yml` file and add the following to the 
`provisioner:` section:
    ```
    provisioner:
        name: chef_zero
        encrypted_data_bag_secret_key_path: "test/fixtures/encrypted_data_bag_secret"
        data_bags_path: "test/fixtures/data_bags"
    ```
1. In your recipe, you would just reference the data bag as normal, e.g.:
    ```
    hab = data_bag_item('credentials', 'hab')
    ```
    because you're running in Test Kitchen, it will use the encryption key you
    already specified, as well as the local data bag. 

## FAQs

1. Should I commit my test encryption key to SCM?
    * That's really up to you, if somone has access to the cookbook code already
    , then they can already piece together the structure of data bag contents if
    they want to. 
