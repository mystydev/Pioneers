#!/bin/bash

if [ "$1" == "make-dev-api" ]; 
then
    docker build -t gcr.io/pioneers-roblox/devpionapi -f src/api/Dockerfile src
    docker push gcr.io/pioneers-roblox/devpionapi

    kubectl scale --replicas=0 deployment/pioneers-dev-api
    kubectl apply -f src/configs/dev-api/deployment.yaml
fi

if [ "$1" == "make-dev-compute-master" ]; 
then
    curl -s -o /dev/null -H "Content-Type: application/json" --request POST  --data @src/configs/PRIVATEdeploymentbody.txt https://api.mysty.dev/pion/updateinitiated
    
    docker build --build-arg TYPE="master" -t gcr.io/pioneers-roblox/devpioncomputemaster src/compute
    docker push gcr.io/pioneers-roblox/devpioncomputemaster

    kubectl scale --replicas=0 deployment/pioneers-dev-compute-master
    curl -s -o /dev/null -H "Content-Type: application/json" --request POST  --data @src/configs/PRIVATEdeploymentbody.txt https://api.mysty.dev/pion/updatedeploying
    kubectl apply -f src/configs/dev-compute-master/deployment.yaml
fi

if [ "$1" == "make-dev-compute-node" ]; 
then
    curl -s -o /dev/null -H "Content-Type: application/json" --request POST  --data @src/configs/PRIVATEdeploymentbody.txt https://api.mysty.dev/pion/updateinitiated

    docker build --build-arg TYPE="node" -t gcr.io/pioneers-roblox/devpioncomputenode src/compute
    docker push gcr.io/pioneers-roblox/devpioncomputenode

    kubectl scale --replicas=0 deployment/pioneers-dev-compute-node
    curl -s -o /dev/null -H "Content-Type: application/json" --request POST  --data @src/configs/PRIVATEdeploymentbody.txt https://api.mysty.dev/pion/updatedeploying
    kubectl apply -f src/configs/dev-compute-node/deployment.yaml
    kubectl apply -f src/configs/dev-compute-node/service.yaml
fi