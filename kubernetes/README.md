# Drupal on EKS

This directory contains Kubernetes manifests for running the containerized Drupal app on EKS Fargate.

## Prerequisites

- An EKS cluster with Fargate enabled.
- `kubectl` configured for the EKS cluster.
- An ECR repository for the Drupal image.
- AWS Load Balancer Controller installed in the cluster for the ALB Ingress.
- Network access from the EKS Fargate pod security group to the RDS security group on port `3306`.

## Fargate Profile

Create a Fargate profile that matches the Drupal namespace and `compute=fargate` pod label:

```bash
eksctl create fargateprofile \
  --cluster "$EKS_CLUSTER" \
  --region us-east-1 \
  --name bincom-drupal \
  --namespace bincom-drupal \
  --labels compute=fargate
```

Or use the template at `kubernetes/eksctl-fargate-profile.yml` after replacing the cluster name.

## Build and Push

From the repository root:

```bash
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO=bincom-drupal
IMAGE_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest"

aws ecr describe-repositories --repository-names "$ECR_REPO" --region "$AWS_REGION" >/dev/null 2>&1 \
  || aws ecr create-repository --repository-name "$ECR_REPO" --region "$AWS_REGION"

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

docker build -t "$IMAGE_URI" kubernetes/docker
docker push "$IMAGE_URI"
```

Update the Deployment image:

```bash
sed -i "s|REPLACE_WITH_ECR_IMAGE_URI|$IMAGE_URI|g" kubernetes/k8s/deployment.yml
```

## Deploy

The easiest path is the deploy script:

```bash
EKS_CLUSTER=your-eks-cluster-name CREATE_FARGATE_PROFILE=true ./kubernetes/deploy-to-eks.sh
```

For manual deployment:

```bash
kubectl apply -f kubernetes/k8s/namespace.yml
kubectl apply -f kubernetes/k8s/configmap.yml
kubectl apply -f kubernetes/k8s/secrets.yml
kubectl apply -f kubernetes/k8s/deployment.yml
kubectl apply -f kubernetes/k8s/service.yml
kubectl apply -f kubernetes/k8s/ingress.yml
```

Check rollout and ingress:

```bash
kubectl -n bincom-drupal rollout status deployment/drupal
kubectl -n bincom-drupal get pods,svc,ingress
```

## Scaling

```bash
kubectl -n bincom-drupal scale deployment/drupal --replicas=3
```

For production, use EFS or S3-backed storage for Drupal uploaded files so all replicas share `sites/default/files`.

On Fargate, use EFS for shared file storage; Fargate does not support EBS-backed persistent volumes the same way EC2 worker nodes do.
