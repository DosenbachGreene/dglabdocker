# Dosenbach and Greene Lab Docker Image

[![CircleCI](https://circleci.com/gh/DosenbachGreene/dglabdocker.svg?style=svg)](https://circleci.com/gh/DosenbachGreene/dglabdocker)

This repo contains the Dockerfile for building the Common Lab docker image. The goal of this repo is to build a docker image with all the dependencies needed to run any script in the lab.

This docker image is based off of Ubuntu 16.04 (xenial)

```
Dosenbach and Greene Lab Docker Image
FROM ubuntu:xenial
MAINTAINER Andrew Van <vanandrew@wustl.edu>
```

## Installation

In general, you would probably not want to build this image directly. Instead, you may opt to pull the official image from dockerhub. You can do this with the following command:
```
docker pull vanandrew/dglabimg:[optional version tag]
```
Alternatively, you can build this docker image with the following command:
```
docker build . -t vanandrew/dglabimg:[optional version tag]
```

## Usage

See our [wiki](https://dosenbachlab.wustl.edu/wiki/docker_singularity/).
