#!/bin/bash

# Run docker to singularity conversion
docker run \
 -v /var/run/docker.sock:/var/run/docker.sock \
 -v $(pwd):/output \
 --privileged -t --rm \
 singularityware/docker2singularity \
 vanandrew/dglabimg
