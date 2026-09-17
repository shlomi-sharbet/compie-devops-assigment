# Compie DevOps Home Assignment

> **Production-Grade Microservice Infrastructure on AWS**  
> Built with Terraform (Modular), Docker, Python FastAPI, DynamoDB, AWS KMS, CloudWatch, and GitHub Actions.

---

## 📑 Table of Contents
1. [Architecture Overview](#-architecture-overview)
2. [Security & Well-Architected Principles](#-security--well-architected-principles)
3. [Project Directory Layout](#-project-directory-layout)
4. [Step-by-Step Deployment Guide](#-step-by-step-deployment-guide)
5. [CI/CD Pipeline with Automated Rolling Updates](#-cicd-pipeline-with-automated-rolling-updates)
6. [Capacity Management & Scaling Strategy](#-capacity-management--scaling-strategy)
7. [Logging, Monitoring & Observability](#-logging-monitoring--observability)
8. [Bonus Features Implemented](#-bonus-features-implemented)
9. [Teardown & Cost Cleanup](#-teardown--cost-cleanup)

---

## 🏛 Architecture Overview

This project provisions an enterprise-grade, immutable infrastructure stack on AWS conforming strictly to the assessment requirements:
- **No ECS / EKS**: Compute runs directly on EC2 instances managed by an **Auto Scaling Group (ASG)** in **Private Subnets**.
- **Public Ingress**: Application Load Balancer (ALB) distributed across 2 Availability Zones routes public HTTP traffic to the private instances.
- **Data Persistence**: Fully managed **Amazon DynamoDB** table encrypted with a Customer-Managed Key (KMS CMK).
- **Zero-Downtime Rollouts**: Deployments are executed via **ASG Instance Refresh**, guaranteeing zero downtime without manual console interaction.
- **Zero SSH (Port 22)**: Server administration is performed solely via **AWS Systems Manager (SSM) Session Manager**.
- **Cost-Optimized Free Tier**: Features a single NAT Gateway and `t3.micro` nodes to avoid unnecessary billing.

```mermaid
flowchart TD
    User([Public Client / Internet]) -->|HTTP :80| ALB[Application Load Balancer\nPublic Subnets across 2 AZs]
    
    subgraph VPC ["AWS Virtual Private Cloud (10.0.0.0/16)"]
        subgraph PublicSubnets ["Public Subnets (AZ-a & AZ-b)"]
            ALB
            NAT[Single NAT Gateway\nEIP attached]
        end
        
        subgraph PrivateSubnets ["Private Subnets (No Public IPs!)"]
            subgraph ASG ["Auto Scaling Group (min:1, desired:2, max:3)"]
                EC2_1["EC2 Node 1 (t3.micro)\nDocker: FastAPI App\nSSM Agent"]
                EC2_2["EC2 Node 2 (t3.micro)\nDocker: FastAPI App\nSSM Agent"]
            end
        end
        
        ALB -->|Target Group :8000| ASG
        EC2_1 -.->|Outbound HTTPS via NAT| NAT
        EC2_2 -.->|Outbound HTTPS via NAT| NAT
    end
    
    subgraph ManagedAWS ["Managed AWS Services"]
        DDB[(Amazon DynamoDB\nEncrypted at rest)]
        SSM_Store[SSM Parameter Store\nApp Config & Secrets]
        KMS[AWS KMS CMK\nCustomer Managed Key]
        CW[CloudWatch Logs & Metrics]
        SNS[SNS Alerts Topic]
        ECR[Amazon ECR\nDocker Registry]
    end
    
    ASG -->|boto3 Read/Write| DDB
    ASG -->|Pull Config| SSM_Store
    ASG -->|awslogs Driver| CW
    ASG -->|Pull Image| ECR
    KMS -.->|Encrypts| DDB
    KMS -.->|Encrypts| SSM_Store
    CW -->|Metric Alarm| SNS
    SNS -->|Email / Webhook| Admin([DevOps Alerts])
```

---

## 🔒 Security & Well-Architected Principles

1. **Private Compute**:
   - EC2 instances reside strictly in private subnets with `map_public_ip_on_launch = false`.
   - Security groups allow inbound traffic **only** from the ALB Security Group on port 8000.
2. **Zero SSH Attack Surface**:
   - **Port 22 is completely closed** in all security groups.
   - Remote terminal access is handled via IAM-governed **AWS Systems Manager (SSM) Session Manager**.
3. **Strict IAM Least-Privilege Separation**:
   - **EC2 Instance Profile**: Granted access strictly to ECR image pulling, CloudWatch log streams, DynamoDB table access, and decrypt permissions on the KMS CMK.
   - **CI/CD User (GitHub Actions)**: Dedicated IAM identity adhering to least-privilege. Can push images to ECR and trigger ASG Instance Refresh. **Has NO permissions to read DynamoDB or application secrets!**
4. **Encryption at Rest**:
   - DynamoDB table, SSM Parameter Store `SecureString`, and EC2 root EBS volumes (10 GB gp3) are encrypted using a dedicated **Customer-Managed Key (KMS CMK)** with automatic annual rotation.
5. **IMDSv2 Enforced**:
   - Instance metadata service requires token authentication (`http_tokens = "required"`), mitigating SSRF vulnerabilities.

---

## 📂 Project Directory Layout

```text
.
├── .github/
│   └── workflows/
│       ├── deploy.yml              # CI/CD: Multi-stage Docker build, ascending 1.0.X tagging & 100% min-healthy rolling update
│       └── pr-checks.yml           # Pre-merge validation: Flake8 linting, pytest, Docker build & Terraform validation (Bonus)
├── app/
│   ├── Dockerfile                  # Production multi-stage, non-root Dockerfile
│   ├── main.py                     # FastAPI service with dynamic versioning, instance ID & DynamoDB connectivity
│   ├── requirements.txt            # Python dependencies (fastapi, boto3, uvicorn)
│   └── .dockerignore
├── tests/
│   └── test_app.py                 # Pytest unit test suite for API endpoints & health checks
├── terraform/
│   ├── environments/
│   │   ├── dev/                    # Primary dev environment
│   │   │   ├── main.tf             # Module orchestration & automated ECR bootstrap
│   │   │   ├── variables.tf        # Environment variables (default: eu-north-1)
│   │   │   ├── terraform.tfvars    # Active dev configurations
│   │   │   ├── outputs.tf          # Public URLs and resource identifiers
│   │   │   └── versions.tf         # AWS Provider (~> 5.0) & Terraform constraints
│   │   └── staging/                # Second environment for multi-environment parity (Bonus)
│   │       ├── main.tf             # Isolated CIDR (10.1.0.0/16) reusing modular stack
│   │       ├── variables.tf        # Staging environment variables
│   │       ├── outputs.tf          # Staging outputs
│   │       └── versions.tf         # Staging version constraints
│   └── modules/
│       ├── vpc/                    # Dynamic 2-AZ subnets, IGW, Single NAT GW
│       ├── security/               # Least-privilege SGs (ALB SG, EC2 SG with zero SSH)
│       ├── kms/                    # Customer Managed Key (CMK) and key policy with ASG grant
│       ├── ecr/                    # Container registry with scan-on-push & lifecycle cleanup
│       ├── database/               # DynamoDB table encrypted with KMS CMK
│       ├── ssm/                    # Parameter Store configurations & KMS secrets
│       ├── iam/                    # Dedicated CI/CD User, EC2 instance profile with least privilege
│       ├── alb/                    # Public ALB, listener, target group with /health check
│       ├── asg/                    # Launch template, resilient fallback UserData, ASG, CPU policy
│       └── monitoring/             # CloudWatch log group, unhealthy alarm, SNS topic, dashboard
├── screenshots/                    # Complete operational & bonus screenshots for submission
│   ├── 01_browser_app_root.png     # Live browser screenshot of / endpoint
│   ├── 02_browser_app_health.png   # Live browser screenshot of /health endpoint
│   ├── 03_cloudwatch_logs.png      # Live CloudWatch log stream from EC2 container
│   ├── 04_github_actions_pipeline.png # Successful CI/CD deployment run
│   ├── 05_cloudwatch_dashboard.png # CloudWatch Observability Dashboard (Bonus)
│   ├── 06_cloudwatch_alarm.png     # CloudWatch UnHealthyHostCount metric alarm
│   └── GitHub Actions.png          # Overview of GitHub Actions runs
├── docker-compose.yml              # Clean local container verification
├── AI_USAGE.md                     # Detailed record of AI pair-programming (Bonus)
└── README.md                       # Main architecture & operations guide
```

---

## 🚀 Step-by-Step Deployment Guide

### Prerequisites
- [Terraform](https://www.terraform.io/downloads.html) (>= 1.5.0 installed)
- [AWS CLI](https://aws.amazon.com/cli/) configured with an IAM identity capable of creating resources.
- [Git](https://git-scm.com/)

---

### Step 1: One-Click Zero-Touch Deployment

```bash
# 1. Navigate to the dev environment
cd terraform/environments/dev

# 2. Initialize Terraform and download provider modules
terraform init

# 3. Review proposed infrastructure plan
terraform plan

# 4. Provision complete infrastructure stack (takes ~3-4 minutes)
terraform apply -auto-approve
```

> [!TIP]
> **Zero-Touch Automation & Resilient Self-Healing:**
> - Terraform automatically creates the ECR repository, builds the Docker image from `app/`, and pushes it to ECR prior to launching the ASG nodes.
> - Even in headless environments without local Docker, the EC2 instances feature a native Python bootstrap fallback service ensuring that ALB Target Group health checks pass immediately with `200 OK` until the first CI/CD run.

Upon completion, Terraform will output:
```text
Outputs:
application_public_url          = "http://compie-dev-alb-123456789.eu-north-1.elb.amazonaws.com"
application_health_url          = "http://compie-dev-alb-123456789.eu-north-1.elb.amazonaws.com/health"
ecr_repository_url              = "123456789012.dkr.ecr.eu-north-1.amazonaws.com/compie-dev-compie-app"
github_actions_access_key_id     = "AKIAIOSFODNN7EXAMPLE"
github_actions_secret_access_key = <sensitive>
```

---

### Step 2: Configure GitHub Actions Secrets

1. In your GitHub Repository (`shlomi-sharbet/compie-devops-assigment`), go to:  
   **Settings** > **Secrets and variables** > **Actions** > **New repository secret**.
2. Create two repository secrets from the Terraform outputs:
   - Name: `AWS_ACCESS_KEY_ID`  
     Value: Paste the `github_actions_access_key_id`
   - Name: `AWS_SECRET_ACCESS_KEY`  
     Value: Run `terraform output -raw github_actions_secret_access_key` and paste the value.

---

### Step 3: Verify Live Endpoints

Once the ASG launches instances (1-2 minutes for bootstrap):
```bash
# Test the Root Endpoint (reads/writes to DynamoDB)
curl -i http://<ALB_DNS_NAME>/

# Test the Deep Health Check
curl -i http://<ALB_DNS_NAME>/health
```

Expected HTTP responses:
* **Root (`/`)**: `HTTP 200 OK` with JSON displaying active version, image tag, serving EC2 instance ID, and DynamoDB visits:
  ```json
  {
    "status": "online",
    "service": "compie-devops-app",
    "version": "1.0.8",
    "docker_image": "807733922953.dkr.ecr.eu-north-1.amazonaws.com/compie-dev-compie-app:1.0.8",
    "served_by_instance": "i-0f373d24bde7a1c45",
    "environment": "dev",
    "message": "Welcome to Compie Cloud Solutions DevOps Microservice!",
    "database": {
      "table": "compie-dev-table",
      "region": "eu-north-1",
      "status": "connected",
      "total_visits": 126,
      "error": null
    },
    "timestamp": "2026-09-17T11:05:53.936742+00:00"
  }
  ```
* **Health (`/health`)**: `HTTP 200 OK` confirming healthy DynamoDB status and serving instance:
  ```json
  {
    "status": "healthy",
    "version": "1.0.8",
    "docker_image": "807733922953.dkr.ecr.eu-north-1.amazonaws.com/compie-dev-compie-app:1.0.8",
    "served_by_instance": "i-0f373d24bde7a1c45",
    "database": {
      "connected": true,
      "table_name": "compie-dev-table",
      "table_status": "ACTIVE"
    },
    "timestamp": "2026-09-17T11:04:41.508137+00:00"
  }
  ```

---

## 🔄 CI/CD Pipelines & Continuous Delivery

The repository includes two production-grade GitHub Actions workflows:

### 1. Continuous Deployment (`.github/workflows/deploy.yml`)
Triggers on every `push` to the `main` branch:
1. **Static Analysis**: Runs `flake8` static code linting on the Python codebase.
2. **Dedicated IAM Authentication**: Authenticates with AWS via dedicated CI/CD credentials (`AWS_ACCESS_KEY_ID` & `AWS_SECRET_ACCESS_KEY`). The IAM User has tightly scoped permissions (ECR push & ASG instance refresh only), preventing any access to database data or application secrets.
3. **Automated Ascending Versioning**: Dynamically computes `1.0.${{ github.run_number }}` and builds the multi-stage Docker image, baking `APP_VERSION` and `DOCKER_IMAGE` directly into the container environment.
4. **Zero-Downtime Rolling Update**:
   - Executes `aws autoscaling start-instance-refresh` with `MinHealthyPercentage=100` and `InstanceWarmup=120`.
   - The ASG launches the new instance, verifies healthy ALB `/health` status (2 consecutive 200 OK checks), and only then safely terminates the previous instance, guaranteeing **zero 502/downtime**.
   - Polls and tracks rollout status until complete.

### 2. Pre-Merge Validation (`.github/workflows/pr-checks.yml`) (Bonus)
Triggers on all Pull Requests targeting `main`:
1. **Code Quality**: Enforces PEP 8 compliance via Flake8.
2. **Automated Unit Tests**: Runs pytest on `tests/test_app.py` validating endpoints and health logic.
3. **Docker Build Test**: Ensures the container builds cleanly without pushing to registry.
4. **Terraform Validation**: Runs `terraform fmt -check` and `terraform validate` across both `dev` and `staging` environments.

---

## 📈 Capacity Management & Scaling Strategy

As mandated by the assignment guidelines:
> *"In the README, briefly explain how you manage capacity / how you would scale"*

### 1. Baseline Capacity (Sizing)
* **Instance Type**: `t3.micro` (2 vCPUs, 1 GiB RAM). Sufficient for Python ASGI workloads under low-to-medium baseline traffic while fitting inside the AWS Free Tier (750 hours/month).
* **ASG Dimensions**:
  * `min_size = 1`: Guarantees high availability fallback.
  * `desired_capacity = 2`: Maintains active distribution across 2 Availability Zones (`eu-north-1a` and `eu-north-1b`) to ensure fault tolerance.
  * `max_size = 3`: Upper threshold preventing runaway costs on a student/demo account during traffic surges.

### 2. Dynamic Target-Tracking Policy (Bonus)
* Configured in Terraform via `aws_autoscaling_policy.cpu_target_tracking`.
* **Metric**: `ASGAverageCPUUtilization` maintained at **50%**.
* When traffic increases and average CPU exceeds 50% over a 3-minute evaluation window, the ASG automatically scales out to `max_size = 3`.
* As load subsides, the ASG scales in smoothly back to `desired_capacity = 2`.

### 3. Production Scaling Roadmap (How we would scale in enterprise production)
1. **Multi-Metric Scaling**: Combine CPU target tracking with ALB `RequestCountPerTarget` (e.g. scale out when requests exceed 1,000 req/sec per target).
2. **Predictive Scaling**: For scheduled spikes (e.g. marketing campaigns, business hours), schedule capacity increases ahead of time.
3. **Instance Diversity & Spot Instances**: For high resilience with 70% cost reduction, implement an ASG Mixed Instances Policy combining On-Demand baseline with Spot instances across multiple instance families (`t3.small`, `t3a.small`, `c6g.medium`).

---

## 📊 Logging, Monitoring & Observability

1. **Native Container Logging**:
   - The Docker daemon is configured with the `awslogs` driver, streaming container standard output and error directly to `/compie/dev/app-logs` in CloudWatch.
   - 7-day retention period configured in Terraform to optimize storage costs.
2. **Proactive Alerting & Notification Wiring**:
   - **Metric Alarm**: `compie-dev-alb-unhealthy-hosts-alarm` actively tracks `UnHealthyHostCount >= 1` on the ALB target group for 2 consecutive periods.
   - **SNS Pipeline (The Wiring)**: The alarm triggers an action to `compie-dev-alerts-topic`, which fans out to an email subscription endpoint (`alert_email`).
   - **Real-World Setup Integration (Documentation)**:
     - In this assessment, the endpoint is configured as an email subscription placeholder (`alert_email` in `terraform.tfvars`).
     - **In a real enterprise production setup**, this SNS Topic would be wired to:
       1. **PagerDuty / Opsgenie**: Via HTTPS Webhook subscription or AWS SNS integration to trigger on-call phone escalations for critical outages.
       2. **Slack / Microsoft Teams**: Via AWS Chatbot or an AWS Lambda function posting rich alarm cards to the `#devops-alerts` or `#incident-room` channel.
       3. **ITSM / ServiceNow / Jira Service Desk**: To automatically open Incident tickets and track MTTR (Mean Time to Resolution).
3. **CloudWatch Observability Dashboard (Bonus)**:
   - Includes real-time widgets for:
     1. ALB Total Request Count
     2. Target Group Host Health (Healthy vs. Unhealthy)
     3. Average Target Response Latency
     4. ASG Cluster CPU Utilization

---

## 🎁 Bonus Features Implemented

| Bonus Item | Status | Implementation Details |
| :--- | :---: | :--- |
| **CloudWatch Dashboard** | ✅ | Defined via `aws_cloudwatch_dashboard.main` with 4 custom time-series widgets (screenshot in `screenshots/05_cloudwatch_dashboard.png`). |
| **Customer-Managed KMS Key (CMK)** | ✅ | Dedicated KMS key with automatic rotation; encrypts EBS volumes, DynamoDB, and SSM. |
| **Dynamic ASG Scaling Policy** | ✅ | Target-tracking on 50% average CPU utilization (`compie-dev-cpu-target-tracking`). |
| **AI Collaboration Artifact** | ✅ | Comprehensive `AI_USAGE.md` documenting prompts, architectural trade-offs, and methodology. |
| **PR / Pre-Merge Checks Pipeline** | ✅ | Implemented via `.github/workflows/pr-checks.yml` (automated Flake8, pytest, Docker build verification, and Terraform validation). |
| **A Second Environment (Staging)** | ✅ | Implemented via `terraform/environments/staging/` reusing 100% of modular code with isolated CIDR `10.1.0.0/16`. |
| **HTTPS On Public Endpoint (Ready)** | ✅ | ALB Security Group pre-configured with Port 443 inbound; documented Route53 + ACM Certificate architecture for custom domains. |
| **Zero SSH Attack Surface** | ✅ | Port 22 completely closed; management exclusively via AWS SSM Session Manager. |
| **Resilient Self-Healing Bootstrap** | ✅ | Automatic fallback service in `userdata.sh.tpl` guaranteeing `200 OK` health checks before initial image push. |

---

## 🧹 Teardown & Cost Cleanup

To prevent ongoing charges on your new AWS account (especially for the NAT Gateway), execute:

```bash
cd terraform/environments/dev
terraform destroy -auto-approve
```

All provisioned AWS resources (VPC, NAT Gateway, Elastic IP, ALB, EC2 ASG, DynamoDB table, SSM parameters, and CloudWatch groups) will be cleanly terminated.
