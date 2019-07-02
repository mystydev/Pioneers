#!/bin/bash


if [ "$1" == "make-dev-compute-master" ]; 
then
    kubectl scale --replicas=0 deployment/pioneers-dev-compute-master

    docker build --build-arg TYPE="master" -t gcr.io/pioneers-237219/devpioncomputemaster backend/compute
    docker push gcr.io/pioneers-237219/devpioncomputemaster

    kubectl apply -f backend/configs/dev-compute-master/deployment.yaml
fi

if [ "$1" == "make-dev-compute-node" ]; 
then
    kubectl scale --replicas=0 deployment/pioneers-dev-compute-node

    docker build --build-arg TYPE="node" -t gcr.io/pioneers-237219/devpioncomputenode backend/compute
    docker push gcr.io/pioneers-237219/devpioncomputenode

    kubectl apply -f backend/configs/dev-compute-node/deployment.yaml
    kubectl apply -f backend/configs/dev-compute-node/service.yaml
fi