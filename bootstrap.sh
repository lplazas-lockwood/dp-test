eksctl create iamserviceaccount \
  --cluster=dp-prod-eu-north-1 \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::019496914213:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

#k8s-bootstrap
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=dp-prod-eu-north- \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=eu-north-1 \
  --set vpcId=vpc-072a4d9acf94fd332

wget https://raw.githubusercontent.com/aws/eks-charts/master/stable/aws-load-balancer-controller/crds/crds.yaml
kubectl apply -f crds.yaml

# k8s-apps
helm upgrade --install -f k8s-apps/dp-golang/values.yaml dp-golang k8s-apps/dp-golang \
  --namespace dp-golang --create-namespace
helm upgrade --install -f k8s-apps/dp-php/values.yaml dp-php k8s-apps/dp-php \
  --namespace dp-php --create-namespace

# argo
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

