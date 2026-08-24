#!/bin/bash

TAG=$(date +%Y%m%d-%H%M%S)
docker build -t chet2026/cdev:${TAG} .
docker push chet2026/cdev:${TAG}


