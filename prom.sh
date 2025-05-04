terraform_version=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version')
curl -O "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip"
unzip terraform_${terraform_version}_linux_amd64.zip
mkdir -p ~/bin
mv terraform ~/bin/
terraform version

sudo mkdir -p /opt/eks
sudo chown cloudshell-user /opt/eks
cd /opt/eks
git clone https://github.com/kodekloudhub/amazon-elastic-kubernetes-service-course
cd amazon-elastic-kubernetes-service-course/eks
source check-environment.sh
terraform init
terraform apply -auto-approve

aws eks update-kubeconfig --region us-east-1 --name demo-eks
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/aws-auth-cm.yaml

apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::891377101284:role/eksWorkerNodeRole
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes


kubectl apply -f aws-auth-cm.yaml



curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.2/deploy/static/provider/aws/deploy.yaml
kubectl get pods --namespace=ingress-nginx

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm pull prometheus-community/kube-prometheus-stack --untar

kubectl create namespace monitoring

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring -f values.yaml

eksctl utils associate-iam-oidc-provider \
  --region us-east-1 \
  --cluster demo-eks \
  --approve