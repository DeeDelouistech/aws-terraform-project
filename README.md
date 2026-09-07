# aws-terraform-project
# AWS Infrastructure, CI/CD, & Serverless AI Pipeline

A production-ready Infrastructure as Code (IaC) project demonstrating modular cloud provisioning on Amazon Web Services (AWS) using **Terraform**, automated CI/CD validation via **GitHub Actions**, and a serverless **Generative AI** integration using **Amazon Bedrock**.

---

## 🏗️ Architecture Overview

This project provisions a secure, modern cloud environment designed for scalability and cost-efficiency:
* **Modular Infrastructure:** Clean separation of configuration blocks for maintainability and reusability.
* **CI/CD Automation:** Automated linting, formatting, and infrastructure validation running on every push via GitHub Actions.
* **Serverless GenAI Integration:** Provisioned AWS Lambda roles and policies configured to securely invoke **Amazon Bedrock** foundation models for smart workload automation.
* **State Management:** Strict adherence to security best practices, excluding local state files and binaries from version control.

---

## 🛠️ Tech Stack

* **Cloud Provider:** AWS (Amazon Web Services)
* **Infrastructure as Code:** Terraform
* **Artificial Intelligence:** Amazon Bedrock (GenAI)
* **Serverless Compute:** AWS Lambda (Python)
* **CI/CD Automation:** GitHub Actions
* **Version Control:** Git & GitHub

---

## 📂 Repository Structure

```text
aws-terraform-project/
├── .github/
│   └── workflows/
│       └── terra-ci.yml    # CI/CD validation pipeline
├── .gitignore              # Excludes local state & provider binaries
├── main.tf                 # Core AWS infrastructure, IAM, Lambda, and Bedrock config
└── README.md               # Project documentation
