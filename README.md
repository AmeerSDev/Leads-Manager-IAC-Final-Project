# Leads Manager
Leads Manager is a Flask + AngularJS web app for managing leads (add/update/delete/close deals) backed by a JSON file. The repo includes Docker, Terraform, and Kubernetes/Helm automation to run it locally or on AWS.

## What’s included
- App: Flask API (`/leads`, `/health`) and AngularJS UI in `app/website`
- Image: `docker/Dockerfile` (Gunicorn on port 5000)
- IaC: Terraform under `iac/terraform` for VPC, ALB, EC2, SGs, subnets, keypair
- Bootstrap: `iac/scripts/user-data-control-plane.sh` builds the Helm chart and deploy script; Service uses NodePort 32000 to container 5000
- CI/CD: `.github/workflows/cicd.yml` builds/pushes `leads-manager` image and applies Terraform + Helm on `main`

## Run locally with Docker
```bash
docker build -t leads-manager -f docker/Dockerfile .
docker run --rm -p 5000:5000 -v "$PWD/tmp-data:/data" -e LEADS_DATA_FILE=/data/leads_data.json leads-manager
# open http://localhost:5000/
```

## Deploy to AWS (summary)
1) Build/push image: `docker build -t <DOCKER_USER>/leads-manager:latest -f docker/Dockerfile . && docker push <DOCKER_USER>/leads-manager:latest`
2) Set `iac/terraform/terraform.tfvars`: AWS creds/region/AMI/instance_type, `docker_repo="<DOCKER_USER>"`.
3) `cd iac/terraform && terraform init && terraform plan -out=tfplan && terraform apply tfplan`.
4) On control plane: `/home/ubuntu/helm/deploy.sh docker.io/<DOCKER_USER>/leads-manager latest`.
5) Grab `ALB-DNS-NAME` from Terraform output and browse `http://<alb-dns>/`.

See `USER-GUIDE.md` for more detail.
