# Kubernetes deployment

- To create DevStats container images use: `DOCKER_USER=... ./k8s/build_images.sh`.
- To drop DevStats container images use: `DOCKER_USER=... ./k8s/remove_images.sh`.
- To test devstats-minimal container image: `AWS_PROFILE=... DOCKER_USER=... ./k8s/test_image.sh devstats`.
