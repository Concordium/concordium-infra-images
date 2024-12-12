# Packer

## Install Packer

```shell
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer
```

From <https://learn.hashicorp.com/tutorials/packer/getting-started-install>

## Build Packer

```shell
packer build jenkins-worker.json
```

or using docker without need to install Packer locally

```shell
docker run \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    --mount type=bind,source="$(pwd)"/packer/jenkins-worker.json,target=/mnt/template.json \
    hashicorp/packer:full-1.7.10 build /mnt/template.json
```

This will produce an ami in `EU-WEST-1` named `jenkins-linux-worker-2.2`, which can be seen here:

<https://eu-west-1.console.aws.amazon.com/ec2/v2/home?region=eu-west-1#Images:sort=name>

If the ami already exists packer will throw an error.

## Remove ami

An generated ami can be removed by deregistering in from here:

<https://eu-west-1.console.aws.amazon.com/ec2/v2/home?region=eu-west-1#Images:sort=name>

But the ami also generates a snapshot which can be deleted from here:

<https://eu-west-1.console.aws.amazon.com/ec2/v2/home?region=eu-west-1#Snapshots:sort=volumeSize>

Where the description of the snapshot will contain the ami id.
