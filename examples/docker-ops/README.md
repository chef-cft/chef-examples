# HowTo - Use Bash Profile Aliases to run Multiple Versions of ChefDK/Workstation Using Docker Containers

This is an example `.bash_profile` or `.zshrc` that allows you to run all 
Chef Workstation (and DK) commands thru the official Chef Docker images. This 
eliminates the need to install the Workstation on your local development 
machine and allows you to quickly and easily switch between new and previous 
versions of Chef. This is important to be able to perform upgrade tasks to 
cookbooks, and also test new versions of the software to ensure compatibility
with your existing Chef code.

## Before You Start

### Assumptions

* Are using macOS or Linux (Windows Powershell coming soon)
* Have an understanding of how to use the `bash_profile` standard, more here:
https://stackoverflow.com/questions/8967843/how-do-i-create-a-bash-alias
* Have Docker installed and running and are able to spin up containers and
connect to the Docker registry
* Are willing to contribute back to this repo with any new cool alias 
corrections or functionality :)

### Tested Versions

* ChefDK/Workstation 1.5 | [`1.5 - thru - Chef Workstation Latest`]
* Automate + Chef Infra Server | [`20201020140427`]
* Docker for Mac | [`Docker version 19.03.8, build afacb8b`]

## Copy the Embedded code into your bash profile file 
(see link in assumptions for the location on your system)

1. Copy this block of code into your profile file:
    ```shell
    # Chef Docker Aliases
    func_chef () {
      kitchen_driver="kitchen-docker"
      image="${1}"
      shift
      args=("${@}")
      if [[ " ${args[@]} " =~ " kitchen " ]]; then
        command="gem install $kitchen_driver; $args;"
      else
        command="$args;"
      fi
      docker run --rm -i -w=/ws \
        -v ~/.aws:/root/.aws \
        -v ~/.gitconfig:/root/.gitconfig \
        -v ~/.chef-workstation/cache/cookbooks/:/root/.chef-workstation/cache/cookbooks \
        -v ~/.chef:/root/.chef \
        -v $PWD:/ws \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /usr/local/bin/docker:/usr/local/bin/docker \
        --network host \
        -e CHEF_LICENSE=accept \
        $image \
        /bin/bash -c "$command"
    }
    chef_12 () {
      image="chef/chefdk:1.5"
      local args=("$@")
      func_chef "$image" "${args[@]}"
    }
    chefdk_1.5 () { chef_12 "$@"; }

    chef_13 () {
      image="chef/chefdk:2.5.3"
      local args=("$@")
      func_chef "$image" "${args[@]}"
    }
    chefdk_2.5.3 () { chef_13 "$@"; }

    chef_14 () {
      image="chef/chefdk:3.13.6"
      local args=("$@")
      func_chef "$image" "${args[@]}"
    }
    chefdk_3.13.6 () { chef_14 "$@"; }

    chef_15 () {
      image="chef/chefworkstation:0.16.31"
      local args=("$@")
      func_chef "$image" "${args[@]}"
    }
    chefws_0.16.31 () { chef_15 "$@"; }

    chef_16 () {
      image="chef/chefworkstation:stable"
      local args=("$@")
      func_chef "$image" "${args[@]}"
    }
    chefws_stable () { chef_16 "$@"; }
    ```
1. Source the profile, on my Mac, using zshrc, I type `source ~/.zshrc`
1. Run commands like this `chef_<version> [chef|knife|kitchen] arg1 arg2 etc....`:
    ```shell
    # Example - knife node list, ChefDK 3.12.10
    > chef_14 knife node list
    hyper-v-00.dbright.io
    hyper-v-01.dbright.io
    nginx.dbright.io
    w2k16-demo-0
    w2k16-demo-1
    w2k16-demo-2
    w2k16-demo1
    w2k16-demo2
    w2k16-demo3
    ymir-api-00.dbright.io
    ymir-backend-00.dbright.io
    ymir-cache-00.dbright.io
    ymir-lb-00.dbright.io

    # Example - kitchen --version, Chef Workstation Stable
    > chef_16 kitchen --version
    Building native extensions. This could take a while...
    Successfully installed bcrypt_pbkdf-1.0.1
    Successfully installed kitchen-docker-2.10.0
    2 gems installed
    Test Kitchen version 2.7.2
1. You can also use the DK or Workstation version when running the commands, 
In the example above, the `chef_<ver>` are mapped to the Chef Infra Client that
ships with the DK/WS image, however you can reference the alias for the DK/WS
version using the alias that's set directly below it - for `chef_15` it is 
`chefws_0.16.31` for example.
1. You will most likely need to tweak the mappings of the Docker run command (
  the ones that start with `-v` to ensure all of the right folders/files are
  being loaded into the Docker container. Once you do this, the commands should
  run successfully.


## FAQs

1. Here's a quick guide to help you choose your Docker image, you can change these at
any time.
    * Chef Client 12.21 -> `docker pull chef/chefdk:1.5`
    * Chef Client 13.8.5 -> `docker pull chef/chefdk:2.5.3`
    * Chef Client 14.14.29 -> `docker pull chef/chefdk:3.12.10`
    * Chef Client 15.8.23 -> `docker pull chef/chefworkstation:0.16.31`
    * Chef Client 16.6.14 -> `docker pull chef/chefworkstation:20.10.168` (also stable as of this doc)
1. The Docker image allows you to run Test Kitchen using the `kitchen-docker` 
driver from within the Docker image itself, it maps to the host Docker socket.
You can change the driver, however I haven't tested this as of yet.

### TODO
* Write Windows Powershell examples
* Test with other drivers
