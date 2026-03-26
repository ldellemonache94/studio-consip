# namespace
kubectl apply -f k8s/namespace.yaml

# build
eval $(minikube docker-env)
docker build -t memory-eater:latest ./app

# deploy
kubectl apply -f k8s/deployment.yaml

# debug
kubectl get pods -n jvm-lab
kubectl logs -f <pod> -n jvm-lab