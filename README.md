# Leads Manager – DevOps Final Project

Flask + AngularJS leads tracker with JSON persistence, containerized with Docker, provisioned to AWS via Terraform, configured with kubeadm/Helm, and automated by GitHub Actions.

## What’s Here
- `app/` Flask API + AngularJS UI, file-based persistence with initial dummy data.
- `docker/Dockerfile` container image (Gunicorn on :5000).
- `iac/terraform/` VPC, ALB, 3 EC2s (control plane + 2 workers), security groups, keypair, outputs.
- `iac/scripts/` user-data for kubeadm + NFS bootstrap and Helm scaffold on the control plane.
- `./.github/workflows/cicd.yml` tests → build/push → Terraform → join workers → Ansible NFS → Helm deploy.
- `./.github/workflows/tests/test_main.py` basic persistence test.

## Prerequisites
- Git, Docker, Terraform ≥ 1.6, kubectl, helm, AWS CLI, Python 3.11+ (for pytest if running locally).
- AWS creds with rights to create VPC/EC2/ALB (use temp sandbox tokens).
- Docker Hub account for pushing the image.
- Never commit real secrets. Use GitHub Secrets for the pipeline; keep local tfvars out of git.

## Local Sanity Check (Docker)
```
git clone https://github.com/AmeerSDev/Leads-Manager-IAC-Final-Project.git
cd Leads-Manager-IAC-Final-Project
docker build -t leads-manager -f docker/Dockerfile .
mkdir -p ./tmp-data
docker run --rm -p 5000:5000 -v "$PWD/tmp-data:/data" -e LEADS_DATA_FILE=/data/leads_data.json leads-manager
# In another shell:
curl http://localhost:5000/health
curl http://localhost:5000/leads
```
Stop with Ctrl+C; data persists in `./tmp-data`.

## Manual AWS Deploy (fresh environment)
1) Set `iac/terraform/terraform.tfvars` locally (do NOT commit real values):
```
aws_region            = "us-east-1"
aws_access_key_id     = "REPLACE_ME"
aws_secret_access_key = "REPLACE_ME"
aws_session_token     = "REPLACE_ME"
ami_id                = "ami-0c398cb65a93047f2"   # adjust per region
instance_type         = "t3.medium"
docker_repo           = "<your_dockerhub_user>"
```
2) Build/push image (optional if already pushed):
```
docker build -t <your_dockerhub_user>/leads-manager:latest -f docker/Dockerfile .
docker push <your_dockerhub_user>/leads-manager:latest
```
3) Terraform:
```
cd iac/terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```
Note outputs: CONTROL-PLANE-PUBLIC-IP, WORKER-1-PUBLIC-IP, WORKER-2-PUBLIC-IP, ALB-DNS-NAME.

4) Join workers (if not auto-joined):
```
ssh -i KP.pem ubuntu@<control_plane_ip>
JOIN_CMD=$(cat /home/ubuntu/join-command.sh)
ssh -i KP.pem ubuntu@10.0.1.11 "sudo hostnamectl set-hostname k8s-worker-1; sudo $JOIN_CMD"
ssh -i KP.pem ubuntu@10.0.2.11 "sudo hostnamectl set-hostname k8s-worker-2; sudo $JOIN_CMD"
kubectl get nodes -o wide
```

5) Deploy app with Helm (on control plane):
```
cd /home/ubuntu/helm
IMAGE_REPO="docker.io/<your_dockerhub_user>/leads-manager"
IMAGE_TAG="latest"
./deploy.sh "$IMAGE_REPO" "$IMAGE_TAG"
kubectl get pods -n default
kubectl get svc leads-manager -n default
```

6) Shared data (NFS) to avoid per-pod drift:
```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: leads-manager-pvc
  namespace: default
spec:
  accessModes: [ "ReadWriteMany" ]
  storageClassName: nfs-client
  resources: { requests: { storage: 1Gi } }
EOF

kubectl set env deployment/leads-manager -n default LEADS_DATA_FILE=/data/leads_data.json
kubectl patch deployment leads-manager -n default --type='json' -p \
'[{"op":"add","path":"/spec/template/spec/containers/0/volumeMounts","value":[]}]' || true
kubectl patch deployment leads-manager -n default --type='json' -p \
'[{"op":"replace","path":"/spec/template/spec/containers/0/volumeMounts","value":[{"name":"leads-data","mountPath":"/data"}]}]'
kubectl patch deployment leads-manager -n default --type='json' -p \
'[{"op":"add","path":"/spec/template/spec/volumes","value":[{"name":"leads-data","persistentVolumeClaim":{"claimName":"leads-manager-pvc"}}]}]' || true
kubectl rollout status deployment/leads-manager -n default
```

7) Test via ALB:
```
curl http://<ALB-DNS-NAME>/health
curl http://<ALB-DNS-NAME>/leads
```

## CI/CD (GitHub Actions)
- Workflow: `.github/workflows/cicd.yml`
  - Runs tests (`pytest .github/workflows/tests`)
  - Builds/pushes Docker image to Docker Hub
  - Runs Terraform (uses repo tf code; generates tfvars from secrets)
  - SSH joins workers, configures NFS via Ansible from control plane
  - Deploys via Helm (`deploy.sh`)
- Required GitHub Secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `AWS_REGION`, `AWS_AMI_ID`, `AWS_INSTANCE_TYPE`, `DOCKER_USERNAME`, `DOCKER_PASSWORD`.
- Trigger: push to `main` or workflow_dispatch.

## Troubleshooting
- 502 from ALB: ensure workers joined; target group healthy on port 32000; service endpoints present.
- Inconsistent data: ensure NFS PVC is mounted and `LEADS_DATA_FILE=/data/leads_data.json`; avoid multiple replicas without shared storage.
- Cred errors: refresh AWS temp tokens; never commit them.
- Slow first response: Gunicorn cold start; persists after first hit.

## Security Notes
- Do not commit secrets. Keep tfvars with real creds untracked; use placeholders in git.
- Rotate any exposed keys immediately.

## License
MIT (see LICENSE).
