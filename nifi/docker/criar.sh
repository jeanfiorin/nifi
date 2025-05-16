

eval $(minikube docker-env)
docker build -t nifi-custom .
docker images
