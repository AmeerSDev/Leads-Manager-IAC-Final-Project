# 🚀 Leads Manager – DevOps Final Project

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Docker](https://img.shields.io/badge/docker-ready-blue)
![Terraform](https://img.shields.io/badge/terraform-1.6+-623CE4)
![Kubernetes](https://img.shields.io/badge/kubernetes-kubeadm-blue)
![License](https://img.shields.io/badge/license-MIT-green)


<p align="center">
  <img 
    src="https://github.com/user-attachments/assets/efa90960-5329-43f6-a62e-39019d0cfad4"
    alt="Gemini_Generated_Image_dprqzpdprqzpdprq"
    width="256"
    height="256"
  />
</p>



A fully containerized **Flask + AngularJS** leads-tracking platform with file-backed JSON persistence, deployed on AWS using Terraform, Kubernetes (kubeadm), Helm, and GitHub Actions CI/CD.

Shared persistent storage is implemented via **NFS**, ensuring consistent state across replicas.

**👨‍💻 Developers:** *Ameer Sobih & Aner Naveh*

---

# 🧩 Architecture Overview

\`\`\`
Flask API  ←→  AngularJS UI
       │
Docker (Gunicorn, port 5000)
       │
Terraform → AWS VPC + ALB + EC2 (1 CP + 2 Workers)
       │
Kubernetes Cluster (kubeadm)
       │
Helm Deployment (deploy.sh)
       │
NFS Server (RWX PVC)
       │
GitHub Actions CI/CD (Build → Push → Terraform → Helm)
\`\`\`

---

# 📁 Repository Structure

| Path | Description |
|------|-------------|
| \`app/\` | Flask API (\`/health\`, \`/leads\`), AngularJS UI, JSON storage |
| \`docker/Dockerfile\` | Production Gunicorn image |
| \`iac/terraform/\` | VPC, ALB, EC2 nodes, security groups, keypair |
| \`iac/scripts/\` | User-data: kubeadm bootstrap + NFS + Helm setup |
| \`helm/\` (generated) | Helm chart + \`deploy.sh\` created on the control plane |
| \`.github/workflows/\` | CI/CD + test workflows |
| \`.github/workflows/tests/test_main.py\` | Data persistence tests |

---

# 📌 Requirements

- Docker  
- Git  
- Terraform **≥ 1.6**  
- AWS CLI  
- kubectl + helm  
- Python 3.11+ (for tests)  
- Docker Hub account  
- AWS sandbox credentials  

> ⚠️ **Never commit secrets or real AWS keys.**  
> Use GitHub Secrets + placeholder tfvars.

---

# 🧭 Manual Deployment Guide (AWS)

## 1️⃣ Clone the repo
```bash
git clone https://github.com/AmeerSDev/Leads-Manager-IAC-Final-Project.git
cd Leads-Manager-IAC-Final-Project
```

---

## 2️⃣ Local Docker test

```bash
docker build -t leads-manager -f docker/Dockerfile .
mkdir -p ./tmp-data

docker run --rm -p 5000:5000 \
  -v "$PWD/tmp-data:/data" \
  -e LEADS_DATA_FILE=/data/leads_data.json \
  leads-manager
```

Test:
```bash
curl http://localhost:5000/health
curl http://localhost:5000/leads
```

---

## 3️⃣ Create \`terraform.tfvars\`

> ⚠️ Do *not* commit this file.

```bash
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

---

## 4️⃣ (Optional) Build & push image

```bash
docker build -t <your_dockerhub_user>/leads-manager:latest -f docker/Dockerfile .
docker push <your_dockerhub_user>/leads-manager:latest
```

---

## 5️⃣ Terraform Deploy

```bash
cd iac/terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

Required outputs:

- Control Plane IP  
- Worker 1 IP  
- Worker 2 IP  
- ALB DNS Name  

---

## 6️⃣ Join Workers (if not auto-joined)

```bash
ssh -i KP.pem ubuntu@<control_plane_ip>
JOIN_CMD=$(cat /home/ubuntu/join-command.sh)

ssh -i KP.pem ubuntu@10.0.1.11 "sudo hostnamectl set-hostname k8s-worker-1; sudo $JOIN_CMD"
ssh -i KP.pem ubuntu@10.0.2.11 "sudo hostnamectl set-hostname k8s-worker-2; sudo $JOIN_CMD"

kubectl get nodes -o wide
```

---

## 7️⃣ Deploy via Helm

```bash
cd /home/ubuntu/helm
IMAGE_REPO="docker.io/<your_dockerhub_user>/leads-manager"
IMAGE_TAG="latest"

./deploy.sh "$IMAGE_REPO" "$IMAGE_TAG"

kubectl get pods
kubectl get svc leads-manager
```

---

## 8️⃣ Add NFS Persistent Volume (shared data)

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: leads-manager-pvc
spec:
  accessModes: ["ReadWriteMany"]
  storageClassName: nfs-client
  resources:
    requests:
      storage: 1Gi
EOF
```

Mount PVC into the deployment:

```bash
kubectl set env deployment/leads-manager LEADS_DATA_FILE=/data/leads_data.json

kubectl patch deployment leads-manager --type=json -p \
'[{"op":"replace","path":"/spec/template/spec/containers/0/volumeMounts","value":[{"name":"leads-data","mountPath":"/data"}]}]'

kubectl patch deployment leads-manager --type=json -p \
'[{"op":"add","path":"/spec/template/spec/volumes","value":[{"name":"leads-data","persistentVolumeClaim":{"claimName":"leads-manager-pvc"}}]}]'

kubectl rollout status deployment/leads-manager
```

---

## 9️⃣ Test through the ALB

```bash
curl http://<ALB-DNS-NAME>/health
curl http://<ALB-DNS-NAME>/leads
```

---

# 🔁 CI/CD Pipeline (GitHub Actions)

**Workflow:** \`.github/workflows/cicd.yml\`

### Pipeline Steps
1. Run tests (\`pytest\`)  
2. Build + push Docker image  
3. Terraform apply  
4. SSH → join workers  
5. Configure NFS  
6. Helm deploy (\`deploy.sh\`)  
7. Output ALB DNS Name  

### Required Secrets

| Secret | Purpose |
|--------|---------|
| \`AWS_ACCESS_KEY_ID\` | AWS auth |
| \`AWS_SECRET_ACCESS_KEY\` | AWS auth |
| \`AWS_SESSION_TOKEN\` | Sandbox token |
| \`AWS_REGION\` | Region |
| \`AWS_AMI_ID\` | EC2 AMI |
| \`AWS_INSTANCE_TYPE\` | Instance size |
| \`DOCKER_USERNAME\` | Docker Hub |
| \`DOCKER_PASSWORD\` | Docker Hub |

### Triggers
- Push to \`main\`  
- PR to \`main\` (tests only)  
- Manual “Run workflow”  

---

# 🛠 Troubleshooting Guide

| Problem | Fix |
|---------|-----|
| **ALB 502** | Workers not joined, or target group unhealthy on port 32000 |
| **Unsynced leads data** | Ensure PVC mounted + \`LEADS_DATA_FILE=/data/leads_data.json\` |
| **AWS credential errors** | Refresh sandbox tokens |
| **Cleanup** | \`terraform destroy\` using the same state |

---

# 🔐 Security

- **Never commit credentials**  
- Always rotate keys if exposed  
- Use GitHub Secrets for CI/CD  
- Use placeholder \`terraform.tfvars\` in repo  

---

# 📄 License
MIT License. See \`LICENSE\`.

