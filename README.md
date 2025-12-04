# Leads Manager – DevOps Final Project

Flask + AngularJS leads tracker with JSON persistence, containerized with Docker, provisioned on AWS via Terraform, bootstrapped with kubeadm/Helm (plus NFS for shared data), and automated by GitHub Actions.

**Developers:** Ameer Sobih & Aner Naveh

## Stack & Layout
- App: `app/` Flask API (`/health`, `/leads`) + AngularJS UI, dummy data on first run, file-backed storage.
- Container: `docker/Dockerfile` (Gunicorn on port 5000).
- IaC: `iac/terraform/` VPC, ALB, 3 EC2s (control plane + 2 workers), SGs, keypair, outputs.
- Bootstrap: `iac/scripts/` user-data for kubeadm, NFS server, Helm scaffold.
- Helm deploy: `/home/ubuntu/helm/deploy.sh` created by user-data on control plane.
- CI/CD: `.github/workflows/cicd.yml` (tests → build/push → Terraform → join workers/NFS → Helm).
- Tests: `.github/workflows/tests/test_main.py` (persistence sanity).

## Prerequisites
- Git, Docker, Terraform ≥ 1.6, kubectl, helm, AWS CLI, Python 3.11+ (for local pytest).
- AWS account (temp sandbox tokens ok) with rights to create VPC/EC2/ALB.
- Docker Hub account (for image push).
- **Never commit real secrets.** Keep tfvars with placeholders; use GitHub Secrets for CI/CD.

## From Git Clone to AWS (Manual Path)
1) Clone:
```
git clone https://github.com/AmeerSDev/Leads-Manager-IAC-Final-Project.git
cd Leads-Manager-IAC-Final-Project
```
2) Local Docker sanity:
```
docker build -t leads-manager -f docker/Dockerfile .
mkdir -p ./tmp-data
docker run --rm -p 5000:5000 -v "$PWD/tmp-data:/data" -e LEADS_DATA_FILE=/data/leads_data.json leads-manager
# new shell:
curl http://localhost:5000/health
curl http://localhost:5000/leads
```
3) Prepare tfvars (do **not** commit real values):
```
cat > iac/terraform/terraform.tfvars <<'EOF'
aws_region            = "us-east-1"
aws_access_key_id     = "REPLACE_ME"
aws_secret_access_key = "REPLACE_ME"
aws_session_token     = "REPLACE_ME"
ami_id                = "ami-0c398cb65a93047f2"
instance_type         = "t3.medium"
docker_repo           = "<your_dockerhub_user>"
EOF
```
4) (Optional) Push image:
```
docker build -t <your_dockerhub_user>/leads-manager:latest -f docker/Dockerfile .
docker push <your_dockerhub_user>/leads-manager:latest
```
5) Terraform (new sandbox/clean state):
```
cd iac/terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```
Capture: CONTROL-PLANE-PUBLIC-IP, WORKER-1-PUBLIC-IP, WORKER-2-PUBLIC-IP, ALB-DNS-NAME.

6) Join workers if they didn’t auto-join:
```
ssh -i KP.pem ubuntu@<control_plane_ip>
JOIN_CMD=$(cat /home/ubuntu/join-command.sh)
ssh -i KP.pem ubuntu@10.0.1.11 "sudo hostnamectl set-hostname k8s-worker-1; sudo $JOIN_CMD"
ssh -i KP.pem ubuntu@10.0.2.11 "sudo hostnamectl set-hostname k8s-worker-2; sudo $JOIN_CMD"
kubectl get nodes -o wide
```

7) Deploy app (control plane):
```
cd /home/ubuntu/helm
IMAGE_REPO="docker.io/<your_dockerhub_user>/leads-manager"
IMAGE_TAG="latest"
./deploy.sh "$IMAGE_REPO" "$IMAGE_TAG"
kubectl get pods -n default
kubectl get svc leads-manager -n default
```

8) Shared data (NFS) to keep replicas in sync:
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

9) Validate via ALB:
```
curl http://<ALB-DNS-NAME>/health
curl http://<ALB-DNS-NAME>/leads
```

## CI/CD (GitHub Actions)
- Workflow: `.github/workflows/cicd.yml`
  - Tests (`pytest .github/workflows/tests`)
  - Build/push Docker image to Hub
  - Terraform apply (tfvars generated from secrets)
  - SSH join workers, configure NFS via Ansible on control plane
  - Helm deploy (`deploy.sh`)
- Required GitHub Secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `AWS_REGION`, `AWS_AMI_ID`, `AWS_INSTANCE_TYPE`, `DOCKER_USERNAME`, `DOCKER_PASSWORD`.
- Trigger: push to `main`, PR to `main` (tests only), or Actions “Run workflow”.
- After success: grab `ALB-DNS-NAME` from Terraform output in logs and hit `/health` and `/leads`.

## Troubleshooting
- 502 from ALB: verify workers joined; target group healthy on port 32000; service endpoints exist.
- Inconsistent data: ensure NFS PVC is mounted and `LEADS_DATA_FILE=/data/leads_data.json`; otherwise scale replicas to 1.
- Cred errors: refresh AWS temp tokens; never commit them.
- To clean up: `terraform destroy` with the same state/creds, or delete stack resources in AWS if state is gone.

## Security Notes
- Do not commit secrets. Keep real tfvars out of git; use placeholders and GitHub Secrets.
- Rotate any exposed keys immediately.

## License
MIT (see LICENSE).
