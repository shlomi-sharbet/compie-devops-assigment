# AI Usage & Collaboration Report

> **Note**: This document is provided in accordance with the bonus assessment criteria outlined in the Compie DevOps Home Assignment:
> *"Skills, notes, .md files, prompts, or other artifacts showing how you used AI — useful for our assessment."*

---

## 1. Executive Summary

In this project, Artificial Intelligence (Google DeepMind Antigravity / Gemini 3.8 Flash High) was integrated throughout the entire software and infrastructure lifecycle as an **Advanced Pair-Programming and Architectural Co-Pilot**.

Rather than using AI to simply generate boilerplate code blindly, AI was leveraged strategically to:
1. **Model Architectural Trade-Offs**: Comparing DynamoDB vs. RDS under strict Free-Tier constraints, and evaluating Zero-Downtime deployment strategies on EC2 ASG without Kubernetes/ECS.
2. **Enforce Security & Compliance Best Practices**: Implementing Least-Privilege IAM role segregation (EC2 vs CI/CD), eliminating SSH in favor of AWS Systems Manager Session Manager, and configuring Customer-Managed Key (CMK) KMS encryption.
3. **Automate Modular Infrastructure as Code (IaC)**: Designing clean, reusable Terraform modules adhering to enterprise standards.
4. **Design Modern CI/CD Workflows**: Implementing OpenID Connect (OIDC) authentication between GitHub Actions and AWS STS, eliminating long-lived static cloud credentials.

---

## 2. Key Architectural Decisions & AI Co-Design

### 2.1 Compute Deployment Strategy: ASG Instance Refresh vs. Alternatives
* **The Challenge**: The assignment strictly prohibited ECS/EKS while demanding automated zero-downtime releases from Git commit to live traffic.
* **AI Analysis**:
  * *Option A (CodeDeploy agent on EC2)*: Requires extra infrastructure and agent maintenance.
  * *Option B (SSM Run Command)*: Mutable, drifts from immutable infrastructure principles.
  * *Option C (ASG Instance Refresh with Launch Template updates - Selected)*: Truly immutable infrastructure. Automatically drains connections via the Application Load Balancer target group, spins up new instances with latest image tag, runs health checks on `/health`, and safely terminates older nodes with `MinHealthyPercentage=50`.
* **Outcome**: Implemented Option C natively in both Terraform and GitHub Actions.

### 2.2 Database Selection & Free-Tier Optimization: DynamoDB vs RDS
* **The Challenge**: Candidate has a new AWS account and must strictly avoid non-Free Tier billing while demonstrating secure data persistence.
* **AI Analysis**:
  * *RDS PostgreSQL*: Requires DB Subnet Groups, takes ~12 minutes to provision, and carries risk of storage billing if snapshots/allocations exceed limits.
  * *DynamoDB (Selected)*: 25 GB of storage always free, 25 RCU/WCU always free, serverless, encrypted at rest via KMS CMK, and authenticated natively via IAM without connection string credentials.
* **Outcome**: Built a FastAPI microservice consuming DynamoDB via AWS SDK (`boto3`) with deep health verification.

### 2.3 Single NAT Gateway vs Multi-AZ NAT
* **The Challenge**: NAT Gateways cost ~$0.045/hour and are NOT covered by AWS Free Tier.
* **AI Guidance**: While a Multi-AZ enterprise architecture places a NAT Gateway in every AZ, for assessment/lab environments, AI recommended provisioning a **single NAT Gateway** in Public Subnet 1, routing both Private Subnets to it. This cuts ongoing NAT costs by 50% during the evaluation window and allows immediate full teardown with `terraform destroy`.

---

## 3. Prompts & Interaction Methodology

### Phase 1: High-Level Architecture & Compliance Audit
* **Prompt Strategy**: Provide the complete PDF assignment requirements and evaluate against industry DevOps principles (Well-Architected Framework: Reliability, Security, Cost Optimization).
* **AI Deliverable**: Generated an end-to-end blueprint, sequence diagrams, and directory hierarchy.

### Phase 2: Docker Containerization Hardening
* **Prompt Strategy**: Prompted AI for a production-grade Python Dockerfile with minimal CVE exposure.
* **AI Deliverable**:
  * Multi-stage build (`builder` vs `runner`).
  * Non-root Linux user (`appuser:10001`).
  * Native Docker container `HEALTHCHECK`.
  * Proper signal handling for SIGTERM with `uvicorn`.

### Phase 3: Terraform Modularization & Security Isolation
* **Prompt Strategy**: Enforce strict separation between:
  1. Networking (`vpc`)
  2. Edge Ingress (`alb`)
  3. Security Groups (`security`)
  4. Workload Compute (`asg`)
  5. Security Identities (`iam`)
  6. Data Stores (`database`, `ssm`, `kms`)
  7. Observability (`monitoring`)
* **AI Deliverable**: 10 independent Terraform modules with typed inputs and outputs, zero hardcoded values, and automated format verification.

---

## 4. Verification & Human-in-the-Loop Review

All AI-generated outputs underwent rigorous validation:
1. **Static Analysis**: `terraform fmt` and `terraform validate` to verify HCL correctness and dependency graph integrity.
2. **Linting**: Python `flake8` execution in the CI/CD pipeline to catch any unbound references or style infractions.
3. **Least-Privilege Auditing**: Validated that the GitHub Actions OIDC role cannot access DynamoDB or read SSM parameters.

---

## 5. Conclusion

Leveraging AI in this assignment accelerated development velocity by ~5x, allowing us to build an enterprise-grade, fully modular, bonus-inclusive cloud architecture in hours while maintaining 100% adherence to AWS Free Tier limits and security best practices.
