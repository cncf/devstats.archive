# Kubernetes deployment

- To create DevStats container images use: `DOCKER_USER=... ./k8s/build_images.sh`.
- To drop DevStats container images use: `DOCKER_USER=... ./k8s/remove_images.sh`.
- To test devstats-minimal container image: `AWS_PROFILE=lfproduct-dev kubectl run -i --tty devstats-minimal --restart=Never --rm --image=lukaszgryglicki/devstats-minimal --command /bin/sh`
