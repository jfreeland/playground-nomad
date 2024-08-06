# playground-nomad

i recently had to do an exercise where i wanted to compare something in
kubernetes vs. nomad. while i worked at hashicorp for a long while, i didn't do
much work in my public repos and thus never had anything like this to borrow
from. leaving it here for future reference.

there are 'could do' and 'would do' sections if i had more time to play with
this for future reference.

## general use

all work was done and tested on mac arm64.

1. there's an assumption baked in that `multipass` uses `192.168.0.0/16`
   - i just launched a multipass vm on my `linux/amd64` ubuntu node and it
     definitely uses something else. `10.177.0.0` in my case.
     - `multipass launch -n test jammy`
     - `multipass info test` - see IPv4
     - `multipass delete -p test`
   - edit `ansible/consul.hcl` to allow other addresses to be included
1. edit `setup.sh` to modify the path to your public key, or be prepared to
   enter the path
1. `make brew` - to install prereqs
1. `make up` - turn up node and services
   - this will dump out urls to poke at
1. `make load` - assumes you have `ab`
   - don't have time to address now, would use `hey` instead
1. look at graphs

## could do

- nix flake, asdf-vm, any number of other ways to pin versions and ensure
  consistent developer experience
- add usage for using `apt` or `snap` instead of `brew`, or nix flake
- use more `Make` instead of bash, but the IP problems are obnoxious and i was
  moving fast
- add auth and functional registry in nomad, `docker buildx build --push` to
  local registry, reference local registry for container

## would do

- pre-commit hooks
- consul dns resolution is not actually working because i didn't get around to
  setting up docker daemon or host resolv to include consul
  - and thus there's a nasty workaround for configuring the datasource
    provisioner
  - i honestly forgot why i got sidetracked on wanting to make consul to work -
    i thought it was going to be meaningful but it's not
- nomad healthcheck out of the box didn't look like it used a separate
  server/port
  - i used a separate server/port because i've seen this pattern often in k8s
- nomad server and agents should all be on private networks completely detached
  from the internet
  - use sshuttle or any number of other technologies to put yourself in private
    network when you need to access them
- vault for secrets management
- nomad, consul, vault namespaces
- redundancy, datacenter names, location-awareness
- tests ... for anything
- autoscaling
