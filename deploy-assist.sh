
//DEV API DEPLOYMENT
kubectl apply -f backend/configs/dev-api/deployment.yaml
kubectl apply -f backend/configs/dev-api/service.yaml
kubectl apply -f backend/configs/dev-api/ingress.yaml

//DEV PROCESSING DEPLOYMENT
kubectl apply -f backend/configs/dev-proc/deployment.yaml
kubectl apply -f backend/configs/dev-proc/service.yaml