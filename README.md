# AWS Secure Network Architecture & IaC Hardening Staging Lab

A production-ready, highly isolated AWS infrastructure built entirely via modular Terraform (HCL). This project demonstrates a Shift Left engineering posture, transitioning an insecure baseline environment into a secure infrastructure tier with 0 Misconfigurations, verified using the Trivy Static Application Security Testing (SAST) compliance engine.

Architecture -[ Public Internet (Repo Mirrors) ]
                                                ▲
                                                │ (Port 443 Outbound)
                                     ┌─────────────────────┐
                                     │  Internet Gateway   │
                                     └──────────▲──────────┘
                                                │
    ┌───────────────────────────────────────────┼────────────────────────┐
    │ Corporate VPC                             │                        │
    │                                           │                        │
    │  ┌────────────────────────────────────────┴─────────────────────┐  │
    │  │ Isolated Subnet Block (10.0.1.0/24)                          │  │
    │  │                                                              │  │
    │  │   ┌────────────────────┐            ┌────────────────────┐   │  │
    │  │   │ Production Server  │───────────►│ Secure Squid Proxy │   │  │
    │  │   │ (Isolated Egress)  │ (Port 3128)│ (Allowed Outbound) │   │  │
    │  │   └────────────────────┘            └────────────────────┘   │  │
    │  └──────────────────────────────────────────────────────────────┘  │
    │                                                                    │
    │  TELEMETRY AUDIT:                                                  │
    │  [ VPC Flow Logs ] ──► [ CloudWatch Logs ] ◄── [ Encrypted by KMS ]│
    └────────────────────────────────────────────────────────────────────┘

Phase 1: The Functional Architecture Baseline
The project began by constructing a core multi-tier infrastructure framework to establish connectivity:

VPC & Subnet Fabric: Provisioned a corporate VPC with an assigned 10.0.1.0/24 subnet mapping block connected to an Internet Gateway at the VPC edge.

Compute Provisioning: Deployed a Linux EC2 web host running an Apache web server. Inital network rules permitted inbound traffic via Ports 80 (HTTP), 443 (HTTPS), and 22 (SSH).
Port 22 (SSH) ingress access was completely disabled directly within the Terraform declarative state code immediately following bootstrap script execution to shrink the perimeter attack surface.

Phase 2: Vulnerability Detection & SAST Security Hardening
To transition the infrastructure into an enterprise compliance posture, a Trivy static analysis linter was run across the HCL directory. The codebase was iteratively re-engineered to remediate the following core structural vulnerabilities:

1. Host Credential Protection (AWS-0028)
Vulnerability: Instance Metadata Service Version 1 (IMDSv1) exposure allowed potential side-channel Server-Side Request Forgery (SSRF) threats to compromise cloud IAM role temporary credentials.
Remediation: Enforced strict IMDSv2 token validation requirements (http_tokens = "required") and restricted the metadata response token hop limit to 1 to eliminate multi-hop extraction vectors.

2. Storage Encryption and Optimization (AWS-0131)
Vulnerability: Unencrypted EBS root block execution drives exposed underlying corporate snapshot data to data-at-rest theft.
Remediation: Configured absolute block storage encryption maps (encrypted = true) across all compute layers and upgraded volumes to the high-throughput gp3 storage framework.

3. Contextual Firewall Auditability (AWS-0124)
Vulnerability: Missing context descriptions within Security Group ingress and egress statement rules restricted administrative audit capabilities.
Remediation: Added descriptive strings to every network boundary block to align with enterprise change-management compliance standards.

4. Cryptographic Telemetry Governance (AWS-0178)
Vulnerability: Lack of packet monitoring visibility across the subnets left network anomalies untracked.
Remediation: Implemented comprehensive VPC Flow Logs streaming parameters directly into an Amazon CloudWatch Log Group. To ensure data sovereignty, the logging repositories were wrapped inside a dedicated AWS KMS Customer Managed Key (CMK) governed by an explicit least-privilege key access policy.

5. Perimeter Segmentation & Outbound Control (AWS-0164 / AWS-0104)
Vulnerability: Subnets automatically mapping public IPv4 addresses combined with unrestricted outbound gates (0.0.0.0/0 over all ports) created severe public exposures.
Remediation: Disabled broad public mapping rules (map_public_ip_on_launch = false) to switch the subnets to fully private, isolated blocks. Established an explicit Layer-7 Squid Proxy filter to intercept internal outbound requests, stripping broad internet access rules down to tightly scoped egress configurations pinned strictly to proxy forwarding interface loops.

Following Phase 2 remediation loops, subsequent static security audits yield a completely clean report.