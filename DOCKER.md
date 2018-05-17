# Install docker

This info is a bit outdated and not tested recently.

- sudo apt-get update
- sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
- curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
- sudo apt-key fingerprint 0EBFCD88
- sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
- sudo apt-get update
- sudo apt-get install docker-ce

Docker can have problems with storage driver, you can select `aufs` storage option by doing:
- `modprobe aufs`
- `vim /etc/docker/daemon.json`, and put storage driver here:
```
{
          "storage-driver": "aufs"
} 
```
