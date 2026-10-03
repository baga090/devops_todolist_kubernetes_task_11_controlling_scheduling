#!/bin/bash
echo "1. Spinning up Kind cluster..."
kind create cluster --config cluster.yml

echo "Waiting for nodes to be ready for labeling/tainting..."
sleep 10

echo "2. Tainting MySQL nodes..."
kubectl taint nodes -l app=mysql app=mysql:NoSchedule

echo "3. Deploying Namespaces..."
kubectl apply -f .infrastructure/namespace.yml

echo "4. Deploying MySQL Database Resources..."
kubectl apply -f .infrastructure/mysql/mysql-secret.yml
kubectl apply -f .infrastructure/mysql/mysql-config.yml
kubectl apply -f .infrastructure/mysql/statefulSet.yml

echo "5. Deploying Application Resources..."
kubectl apply -f .infrastructure/app-db-secret.yml
kubectl apply -f .infrastructure/configMap.yml
kubectl apply -f .infrastructure/secret.yml
kubectl apply -f .infrastructure/pv.yml
kubectl apply -f .infrastructure/pvc.yml
kubectl apply -f .infrastructure/deployment.yml

echo "6. Deploying Ingress Controller & Routing..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
sleep 15
kubectl apply -f .infrastructure/ingress/ingress.yml

echo "Deployment complete!"