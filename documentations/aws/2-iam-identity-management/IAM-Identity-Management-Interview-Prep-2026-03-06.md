# IAM & Identity Management — Senior DevOps Interview Preparation

> **Topic**: IAM & Identity Management  
> **Subtopics**: IAM Users/Groups/Roles/Policies · STS · Permission Boundaries · Identity Federation · Service Roles  
> **Audience**: Senior DevOps / Cloud Engineers  
> **Accuracy**: Current as of 2025–2026  
> **Date**: March 6, 2026

---

## Table of Contents

1. [Table of Contents](#table-of-contents)
2. [Introduction](#introduction)
3. [Foundational Concepts — IAM Users, Groups, Roles & Policies](#foundational-concepts--iam-users-groups-roles--policies)
4. [Foundational Concepts — STS (Security Token Service)](#foundational-concepts--sts-security-token-service)
5. [Foundational Concepts — Permission Boundaries](#foundational-concepts--permission-boundaries)
6. [Foundational Concepts — Identity Federation](#foundational-concepts--identity-federation)
7. [Foundational Concepts — Service Roles](#foundational-concepts--service-roles)
8. [Detailed Explanations & Examples — IAM Users, Groups, Roles & Policies](#detailed-explanations--examples--iam-users-groups-roles--policies)
9. [Detailed Explanations & Examples — STS](#detailed-explanations--examples--sts)
10. [Detailed Explanations & Examples — Permission Boundaries](#detailed-explanations--examples--permission-boundaries)
11. [Detailed Explanations & Examples — Identity Federation](#detailed-explanations--examples--identity-federation)
12. [Detailed Explanations & Examples — Service Roles](#detailed-explanations--examples--service-roles)
13. [Hands-On Scenarios — IAM Users, Groups, Roles & Policies](#hands-on-scenarios--iam-users-groups-roles--policies)
14. [Hands-On Scenarios — STS](#hands-on-scenarios--sts)
15. [Hands-On Scenarios — Permission Boundaries](#hands-on-scenarios--permission-boundaries)
16. [Hands-On Scenarios — Identity Federation](#hands-on-scenarios--identity-federation)
17. [Hands-On Scenarios — Service Roles](#hands-on-scenarios--service-roles)
18. [Most Asked Interview Questions with Answers](#most-asked-interview-questions-with-answers)
19. [Common Mistakes & How to Avoid Them](#common-mistakes--how-to-avoid-them)

---

## Introduction

AWS Identity and Access Management (IAM) is the foundational security layer that governs every interaction between human users, applications, and AWS services within the cloud. In the DevOps context, IAM is not merely an administrative tool—it is a core engineering discipline that directly affects deployment pipelines, service-to-service communication, cross-account automation, and regulatory compliance. Modern DevOps practices such as infrastructure-as-code (IaC), GitOps, and continuous delivery all require precise, least-privilege IAM configurations that are version-controlled, peer-reviewed, and automatically audited. A single misconfigured policy or an overly permissive role can expose an entire organization's data, disrupt production workloads, or violate compliance frameworks such as SOC 2, PCI-DSS, or HIPAA.

IAM's relevance in cloud infrastructure has grown exponentially as organizations adopt multi-account strategies, hybrid cloud architectures, and zero-trust security models. Senior DevOps engineers are expected to design IAM architectures that span AWS Organizations, configure trust relationships between AWS accounts, integrate corporate identity providers via federation, and enforce granular permission boundaries across automated CI/CD systems. The shift from long-lived access keys to ephemeral credentials issued by STS, from hardcoded secrets to role-based access, and from manual policy creation to policy-as-code with tools like AWS CDK, Terraform, and CloudFormation represents the evolution every senior practitioner must master.

This document covers the five most interview-critical IAM domains: the core building blocks of Users, Groups, Roles, and Policies; the Security Token Service (STS) for temporary credential issuance; Permission Boundaries as a delegation guardrail; Identity Federation for integrating external IdPs; and Service Roles that power secure service-to-service automation. All content reflects IAM capabilities and best practices current as of early 2026, including IAM Identity Center (successor to AWS SSO), ABAC (Attribute-Based Access Control), and AWS Organizations integration.

---

## Foundational Concepts — IAM Users, Groups, Roles & Policies

### Definition

AWS IAM Users, Groups, Roles, and Policies form the core access control model of AWS. A **User** is a permanent identity representing a human or service account. A **Group** is a logical collection of users that share common policy attachments. A **Role** is a temporary, assumable identity with defined trust and permission policies, designed for short-lived access. A **Policy** is a JSON document specifying allowed or denied actions on AWS resources. Together, these primitives implement the principle of least privilege—granting only the minimum permissions required for a task—across individuals, teams, and automated systems.

### Key Components

| Component | Description |
|---|---|
| **IAM User** | Permanent AWS identity with long-term credentials (password + access keys). Used for human operators or legacy service accounts. |
| **IAM Group** | Collection of users; policies attached to a group apply to all its members. Groups cannot be nested. |
| **IAM Role** | Assumable identity used by AWS services, users, or external principals. Provides temporary credentials via STS. |
| **Managed Policy** | Standalone JSON policy document maintained independently and attachable to multiple principals. |
| **Inline Policy** | Embedded policy directly attached to a single user, group, or role. Deleted with the principal. |
| **Resource-Based Policy** | Attached directly to a resource (e.g., S3 bucket policy, Lambda resource policy). Specifies who can access the resource. |
| **Policy Evaluation Logic** | AWS evaluates all applicable policies: explicit Deny > explicit Allow (with SCP and boundary constraints). |

### Use Cases

- **IAM Users**: Bootstrapping a brand-new AWS account; creating a break-glass emergency admin account.
- **IAM Groups**: Organizing developers, data engineers, or DBAs with shared permission sets.
- **IAM Roles**: EC2 instance profiles, Lambda execution roles, ECS task roles, cross-account access.
- **Managed Policies**: Defining reusable `ReadOnlyAccess` or `S3BucketAccess` patterns across dozens of roles.
- **Inline Policies**: Attaching environment-specific one-off policies that must not be accidentally shared.

---

## Foundational Concepts — STS (Security Token Service)

### Definition

AWS Security Token Service (STS) is a global web service that issues temporary, limited-privilege security credentials for IAM or federated users. Unlike long-term access keys, STS credentials consist of an Access Key ID, a Secret Access Key, and a Session Token—all with a configurable expiry (15 minutes to 36 hours). STS is the engine behind role assumption, cross-account access, identity federation, and EC2 instance profiles. Because credentials are ephemeral, they dramatically reduce the attack surface associated with credential leakage and eliminate the operational burden of manual key rotation.

### Key Components

| Component | Description |
|---|---|
| **AssumeRole** | Allows an IAM principal or federated identity to assume an IAM role and obtain temporary credentials. |
| **AssumeRoleWithWebIdentity** | Issues credentials after validating an OIDC token from providers like Cognito, GitHub Actions, or Google. |
| **AssumeRoleWithSAML** | Federates SAML 2.0 assertions from corporate IdPs (AD FS, Okta) into temporary AWS credentials. |
| **GetFederationToken** | Issues credentials scoped to a subset of the caller's permissions; used for custom identity brokers. |
| **GetSessionToken** | Enforces MFA for IAM users by issuing temporary credentials after MFA validation. |
| **Session Policies** | Inline policies passed at assume-role time to further restrict permissions beyond what the role allows. |
| **External ID** | A shared secret in the trust policy to prevent confused deputy attacks in third-party cross-account scenarios. |

### Use Cases

- GitHub Actions assuming an AWS role via OIDC without storing access keys in CI secrets.
- Multi-account pipeline: the build account assumes a deployment role in the target account.
- Enforcing MFA via `GetSessionToken` before allowing sensitive operations.
- Lambda functions receiving temporary credentials automatically at invocation via the execution role.

---

## Foundational Concepts — Permission Boundaries

### Definition

A Permission Boundary is an advanced IAM feature that sets the maximum permissions a principal (user or role) can exercise, regardless of identity-based policies attached to that principal. Boundaries do not grant permissions themselves—they act as a ceiling. If a role has `AdministratorAccess` but its boundary only allows `s3:*`, the effective permissions are only S3 actions. This mechanism enables safe delegation: a central platform team can authorize developers to create roles themselves, confident that no role created by a developer can exceed the boundary defined by the platform team. Boundaries are defined as managed policies and attached to roles or users via `iam:PutRolePowerBoundary`.

### Key Components

| Component | Description |
|---|---|
| **Boundary Policy Document** | A standard IAM policy JSON that specifies the maximum allowable action set. |
| **Effective Permission Intersection** | `effective_permissions = identity_policy ∩ boundary`. Both must allow an action for it to be permitted. |
| **Delegation Pattern** | Platform teams set boundaries; developers can create/modify roles only if those roles carry the boundary. |
| **`iam:PassRole` with Condition** | Ensures developers can only pass roles that have the boundary attached. |
| **No Effect on Resource-Based Policies** | Boundaries restrict identity-based policies only; resource-based policies granting cross-account access are evaluated separately. |
| **AWS Organizations SCPs** | SCPs (Service Control Policies) operate at the account level; boundaries operate at the principal level. Both must allow an action. |

### Use Cases

- Allowing a developer team to self-service IAM role creation without risking privilege escalation.
- Constraining CI/CD pipeline roles so they can only act within specific regions or services.
- Compliance enforcement: ensuring no role in a regulated workload account can access billing or delete CloudTrail.

---

## Foundational Concepts — Identity Federation

### Definition

Identity Federation allows external identities—from corporate directories, social providers, or custom identity brokers—to authenticate with AWS without creating corresponding IAM users. AWS supports two primary federation standards: **SAML 2.0** for enterprise SSO (Active Directory, Okta, Ping) and **OpenID Connect (OIDC)** for web/mobile and CI/CD integrations (GitHub Actions, GitLab, Cognito). Federated users receive temporary STS credentials scoped to a mapped IAM role. AWS IAM Identity Center (formerly AWS SSO) extends federation across AWS Organizations, providing centralized access management at scale with fine-grained permission sets and integration with AWS managed AD or external SAML providers.

### Key Components

| Component | Description |
|---|---|
| **SAML 2.0 Provider** | IAM entity created to represent a SAML IdP; configured with IdP metadata XML. |
| **OIDC Provider** | IAM entity representing an OIDC IdP; holds the provider URL and audience (client ID). |
| **Role for Federation** | IAM role whose trust policy allows `sts:AssumeRoleWithSAML` or `sts:AssumeRoleWithWebIdentity`. |
| **IAM Identity Center** | Managed SSO service supporting SAML federation, SCIM provisioning, and per-account/per-app permission sets. |
| **Attribute Mapping** | SAML assertions or OIDC claims mapped to IAM session tags for ABAC-based access control. |
| **SCIM Provisioning** | Automated user/group sync from IdP to IAM Identity Center, eliminating manual user management. |
| **Custom Identity Broker** | Internal service that authenticates users and calls `GetFederationToken` to issue scoped AWS credentials. |

### Use Cases

- Corporate employees accessing the AWS Console via Okta SAML without individual IAM users.
- GitHub Actions workflow authenticating to AWS via OIDC, eliminating stored access keys in GitHub Secrets.
- Mobile app users accessing their private S3 objects using Cognito-federated temporary credentials.

---

## Foundational Concepts — Service Roles

### Definition

A Service Role is an IAM Role that an AWS service assumes on your behalf to perform actions against other AWS services. It is defined with a trust policy that specifies the AWS service principal (e.g., `ec2.amazonaws.com`, `lambda.amazonaws.com`) as the trusted entity, and a permission policy that grants what that service is allowed to do. Service roles follow the same least-privilege principle: a Lambda function that reads DynamoDB and writes to SQS should have only those specific permissions. Service roles are distinct from service-linked roles (SLRs), which are pre-defined by AWS and cannot be independently modified. For compute workloads, instance profiles act as the container that associates a role with an EC2 instance.

### Key Components

| Component | Description |
|---|---|
| **Trust Policy** | Defines which service principal (`ec2.amazonaws.com`, `ecs-tasks.amazonaws.com`) can assume the role. |
| **Permission Policy** | Grants the service permission to call downstream AWS APIs. |
| **Instance Profile** | Wrapper resource that associates a role to an EC2 instance; EC2 retrieves credentials via IMDSv2. |
| **ECS Task Role** | Role assumed at the container level by the ECS task; separate from the task execution role. |
| **Service-Linked Role (SLR)** | Pre-created by AWS for specific services (e.g., `AWSServiceRoleForEC2Spot`); cannot be directly modified. |
| **IMDSv2** | EC2 Instance Metadata Service v2; enforced session-oriented protocol for retrieving role credentials securely. |
| **PassRole Permission** | `iam:PassRole` must be granted to whoever creates/launches the service so the service can assume the role. |

### Use Cases

- EC2 instances in an autoscaling group reading configs from SSM Parameter Store via an instance profile.
- ECS Fargate tasks writing to S3 and reading secrets from Secrets Manager.
- CodePipeline assuming a cross-account deployment role in the production account.
- EventBridge scheduling Lambda invocations using a service role with `lambda:InvokeFunction`.

---

## Detailed Explanations & Examples — IAM Users, Groups, Roles & Policies

### a) Textual Deep Dive

IAM's policy evaluation engine is the most critical—and most misunderstood—aspect of AWS security. When a principal makes an API call, AWS evaluates policies in the following order: (1) Organization Service Control Policies (SCPs), (2) Resource-based Policies, (3) Identity-based Policies, (4) IAM Permission Boundaries, (5) Session Policies. An **explicit Deny** at any layer immediately blocks the request. An **explicit Allow** must be present in at least one applicable policy, and no other layer must deny it.

IAM Policies are JSON documents with five basic statement elements: `Effect`, `Action`, `Resource`, `Principal` (for resource-based policies), and `Condition`. The `Condition` block is extremely powerful—it supports global keys (`aws:RequestedRegion`, `aws:CurrentTime`, `aws:PrincipalTag`) and service-specific keys, enabling attribute-based access control (ABAC). ABAC scales better than traditional RBAC because access decisions are driven by tags on both principals and resources, eliminating the need to create and maintain dozens of roles.

Best practices at the senior level include: always using managed policies over inline for reusability and auditing; leveraging AWS-managed policies (`ReadOnlyAccess`, `AmazonS3ReadOnlyAccess`) as a starting point modified to organizational requirements; versioning policy documents in git; using IAM Access Analyzer to validate policies against least-privilege recommendations and detect external access to resources; and running `aws iam simulate-principal-policy` in CI pipelines to prevent regression of critical denies.

### b) Practical Code Examples

**Example 1: Least-Privilege S3 Read Policy with Conditions**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ReadInProdBucket",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:GetObjectVersion"
      ],
      "Resource": [
        "arn:aws:s3:::my-prod-bucket",
        "arn:aws:s3:::my-prod-bucket/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1",
          "s3:prefix": ["reports/", "exports/"]
        },
        "Bool": {
          "aws:SecureTransport": "true"
        }
      }
    }
  ]
}
```

> This policy allows listing and reading only under specific prefixes, enforces HTTPS, and restricts to a single region. This prevents unintentional access to other prefixes or over unencrypted connections.

**Example 2: ABAC Policy Using Principal and Resource Tags**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ABACAccessByEnvironmentTag",
      "Effect": "Allow",
      "Action": [
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:RebootInstances"
      ],
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/Environment": "${aws:PrincipalTag/Environment}",
          "ec2:ResourceTag/Team":        "${aws:PrincipalTag/Team}"
        }
      }
    }
  ]
}
```

> Users tagged `Environment=prod` and `Team=platform` can only control EC2 instances that carry matching tags, eliminating the need for environment-specific roles.

**Example 3: Terraform — Creating a Role with Managed and Inline Policies**

```hcl
resource "aws_iam_role" "app_role" {
  name = "app-deployment-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Environment = "prod"
    Team        = "platform"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "inline_s3" {
  name = "inline-s3-access"
  role = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject"]
      Resource = "arn:aws:s3:::my-app-artifacts/*"
    }]
  })
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "app-instance-profile"
  role = aws_iam_role.app_role.name
}
```

> This Terraform module creates a role, attaches an AWS-managed policy for SSM access, adds an inline policy for a specific S3 bucket, and wraps the role in an instance profile for EC2 use.

### c) ASCII Diagrams

**Diagram 1: IAM Policy Evaluation Order**

```
┌──────────────────────────────────────────────────────────────────────┐
│                     IAM Policy Evaluation Flow                       │
└──────────────────────────────────────────────────────────────────────┘

  API Request from Principal
           │
           ▼
  ┌─────────────────┐     DENY?
  │ 1. SCPs (Org)   │──────────────────────────────► ACCESS DENIED
  └────────┬────────┘
           │ (No Deny)
           ▼
  ┌──────────────────────┐  DENY or no ALLOW to
  │ 2. Resource-Based    │  cross-account principal?► ACCESS DENIED
  │    Policy            │
  └──────────┬───────────┘
             │ (No Deny, Allow present or same-account)
             ▼
  ┌──────────────────────┐
  │ 3. Identity-Based    │  DENY?──────────────────► ACCESS DENIED
  │    Policies          │
  └──────────┬───────────┘
             │ (No Deny)
             ▼
  ┌──────────────────────┐
  │ 4. Permission        │  Action outside boundary?► ACCESS DENIED
  │    Boundaries        │
  └──────────┬───────────┘
             │ (Within boundary)
             ▼
  ┌──────────────────────┐
  │ 5. Session Policies  │  Action not allowed?────► ACCESS DENIED
  └──────────┬───────────┘
             │ (Allowed)
             ▼
         ACCESS GRANTED

Legend:
  ──► = Decision path
  SCPs = Service Control Policies (AWS Organizations)
```

**Diagram 2: IAM Entity Relationships**

```
┌─────────────────────────────────────────────────────────────┐
│                  AWS Account IAM Model                       │
└─────────────────────────────────────────────────────────────┘

  ┌──────────────┐     member of     ┌──────────────┐
  │   IAM User   │──────────────────►│   IAM Group  │
  │  (alice)     │                   │  (developers) │
  └──────┬───────┘                   └──────┬───────┘
         │                                  │
         │ attached                         │ attached
         ▼                                  ▼
  ┌──────────────┐                   ┌──────────────┐
  │   Inline     │                   │   Managed    │
  │   Policy     │                   │   Policy     │
  └──────────────┘                   └──────────────┘

  ┌──────────────┐  trust policy  ┌───────────────────────┐
  │  IAM Role    │◄───────────────│  Trusted Principal:   │
  │  (app-role)  │                │  · IAM User/Role      │
  └──────┬───────┘                │  · AWS Service        │
         │                        │  · Federated Identity │
         │ attached               └───────────────────────┘
         ▼
  ┌──────────────┐
  │  Permission  │
  │   Policy     │
  └──────────────┘

  ┌──────────────────────────────────────────┐
  │ AWS Resource (e.g., S3 Bucket)           │
  │  └── Resource-Based Policy               │
  │       (who can access this resource)     │
  └──────────────────────────────────────────┘
```

---

## Detailed Explanations & Examples — STS

### a) Textual Deep Dive

AWS STS is a regional service (with a global endpoint at `sts.amazonaws.com` that defaults to `us-east-1`) that issues short-lived credentials. From an architectural perspective, STS is the single most important service for eliminating static credentials in modern AWS deployments. Every EC2 instance profile, Lambda execution role, ECS task role, and GitHub Actions OIDC integration relies on STS under the hood.

The `AssumeRole` API call requires the caller to have `sts:AssumeRole` permission against the target role ARN, and the target role's trust policy must list the caller as a trusted principal. Session duration ranges from 15 minutes to 12 hours (up to 36 hours if the role's `MaxSessionDuration` is extended). The returned credentials include `AccessKeyId`, `SecretAccessKey`, `SessionToken`, and `Expiration`. All downstream AWS SDK calls must include the session token in the `X-Amz-Security-Token` header.

For cross-account patterns, an organization's tooling account assumes a deployment role in target accounts. The trust relationship specifies the source account's IAM role ARN, and an `ExternalId` condition prevents third-party services from abusing the trust relationship (confused deputy attack). STS also supports **session tags** and **transitive session tags**, which enable attribute-based access control to flow through role chains.

Best practices: configure STS regional endpoints (avoid the global endpoint for latency and resilience); set the shortest practical session duration; use `ExternalId` for all third-party trusts; never persist STS tokens to disk; and audit role assumptions via CloudTrail `AssumeRole` events.

### b) Practical Code Examples

**Example 1: Assuming a Cross-Account Role via AWS CLI**

```bash
# Assume a deployment role in the production account
CREDS=$(aws sts assume-role \
  --role-arn "arn:aws:iam::111122223333:role/ProdDeploymentRole" \
  --role-session-name "ci-pipeline-$(date +%s)" \
  --duration-seconds 3600 \
  --external-id "unique-shared-secret-abc123" \
  --query 'Credentials' \
  --output json)

# Export temporary credentials
export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | jq -r '.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r '.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$CREDS" | jq -r '.SessionToken')

# Verify identity in the target account
aws sts get-caller-identity
```

> The `ExternalId` matches the value in the role's trust policy, preventing confused deputy attacks. `jq` parses the JSON response. Session credentials auto-expire after 3600 seconds.

**Example 2: GitHub Actions OIDC — Assume Role Without Access Keys**

```yaml
# .github/workflows/deploy.yml
name: Deploy to AWS

on:
  push:
    branches: [main]

permissions:
  id-token: write   # Required for OIDC token issuance
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::111122223333:role/GitHubActionsDeployRole
          role-session-name: github-actions-deploy
          aws-region: us-east-1
          role-duration-seconds: 1800

      - name: Deploy CDK stack
        run: npx cdk deploy --require-approval never MyAppStack
```

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::111122223333:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:my-org/my-repo:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

> The trust policy restricts assumption to a specific GitHub repository and branch, preventing other repos from assuming this role.

**Example 3: Python Boto3 — Role Chaining with Session Tags**

```python
import boto3

def get_cross_account_session(
    role_arn: str,
    session_name: str,
    environment: str,
    team: str,
    duration: int = 3600
) -> boto3.Session:
    """
    Assume a role with session tags for ABAC-aware downstream calls.
    Enables attribute-based access control on the assumed session.
    """
    sts_client = boto3.client("sts", region_name="us-east-1")

    response = sts_client.assume_role(
        RoleArn=role_arn,
        RoleSessionName=session_name,
        DurationSeconds=duration,
        Tags=[
            {"Key": "Environment", "Value": environment},
            {"Key": "Team",        "Value": team},
        ],
        TransitiveTagKeys=["Environment", "Team"],  # Tags propagate through chained roles
    )

    creds = response["Credentials"]
    return boto3.Session(
        aws_access_key_id=creds["AccessKeyId"],
        aws_secret_access_key=creds["SecretAccessKey"],
        aws_session_token=creds["SessionToken"],
        region_name="us-east-1",
    )


# Usage
session = get_cross_account_session(
    role_arn="arn:aws:iam::111122223333:role/DataEngRole",
    session_name="etl-pipeline-job-42",
    environment="prod",
    team="data-engineering",
)

s3 = session.client("s3")
response = s3.list_buckets()
print(response["Buckets"])
```

### c) ASCII Diagrams

**Diagram 1: STS AssumeRole Cross-Account Flow**

```
  Account A (Tooling / Build)          Account B (Production)
  ┌──────────────────────────┐         ┌──────────────────────────┐
  │                          │         │                          │
  │  ┌──────────────────┐    │         │  ┌──────────────────┐    │
  │  │  IAM Role        │    │  1.AssumeRole  │  ProdDeployRole  │    │
  │  │  (CI Pipeline)   │────┼─────────►  (Trust: Account A) │    │
  │  └──────────────────┘    │         │  └────────┬─────────┘    │
  │                          │         │           │              │
  │                          │  2. Temp Credentials              │
  │                          │◄──────────────────┘               │
  │                          │         │                          │
  │  ┌──────────────────┐    │         │  ┌──────────────────┐    │
  │  │  Pipeline uses   │    │ 3. API  │  │  AWS Services    │    │
  │  │  temp creds      │────┼─────────►  │  (ECS, S3, etc)  │    │
  │  └──────────────────┘    │         │  └──────────────────┘    │
  │                          │         │                          │
  └──────────────────────────┘         └──────────────────────────┘

  4. CloudTrail records AssumeRole event with:
     - Source role ARN (Account A)
     - Target role ARN (Account B)
     - Session name, ExternalId, duration
```

**Diagram 2: GitHub Actions OIDC Token Exchange**

```
  GitHub Actions Runner           AWS STS / OIDC Provider
  ┌─────────────────────┐         ┌───────────────────────────┐
  │                     │         │                           │
  │  1. Request OIDC    │         │  ┌─────────────────────┐  │
  │     JWT Token       │         │  │  OIDC Provider:     │  │
  │         │           │         │  │  token.actions      │  │
  │         ▼           │         │  │  .githubusercontent  │  │
  │  ┌─────────────┐    │         │  │  .com               │  │
  │  │  JWT Token  │──2.AssumeRole│  └──────────┬──────────┘  │
  │  │  (signed by │────WithWebId─►             │             │
  │  │  GitHub)    │    entity   │  3. Validates JWT signature │
  │  └─────────────┘    │         │     & conditions          │
  │                     │         │  4. Issues temp creds     │
  │  ┌─────────────┐    │◄─────────────────────┘             │
  │  │ Temp AWS    │◄───┘         │                           │
  │  │ Credentials │              └───────────────────────────┘
  │  └──────┬──────┘
  │         │ 5. Use credentials
  │         ▼
  │  AWS API Calls
  └─────────────────────┘

  No long-lived access keys stored in GitHub Secrets.
```

---

## Detailed Explanations & Examples — Permission Boundaries

### a) Textual Deep Dive

Permission Boundaries solve a specific and critical problem: how do you safely delegate the ability to create and manage IAM roles to developers or automation systems without risking privilege escalation? Without boundaries, any principal with `iam:CreateRole` and `iam:AttachRolePolicy` can create a role with `AdministratorAccess`, defeating your entire security model.

With boundaries, the workflow is: (1) The platform/security team creates a boundary policy that defines the maximum allowed actions for developer-created roles. (2) The platform team creates a *delegation policy* for developers that allows `iam:CreateRole`, `iam:AttachRolePolicy`, etc., but only when the action includes a condition that the new role must have the boundary attached (using `iam:PermissionsBoundary` condition key). (3) The condition also prevents developers from passing roles without the boundary to AWS services, and from creating policies or modifying the boundary itself.

The delegation policy typically includes four protection conditions:
- `iam:PermissionsBoundary` must equal the boundary ARN when creating/updating a role.
- `iam:PassRole` only allowed for roles that carry the boundary.
- Deny `iam:CreatePolicyVersion`, `iam:DeletePolicy`, `iam:SetDefaultPolicyVersion` on the boundary policy.
- Deny `iam:DeleteRolePermissionsBoundary` on any role.

This creates an unbreakable enforcement chain: developers cannot escaping the boundary constraints because modifying or removing the boundary is denied.

### b) Practical Code Examples

**Example 1: Permission Boundary Policy**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowServicesWithinBoundary",
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "dynamodb:*",
        "sqs:*",
        "sns:*",
        "lambda:*",
        "logs:*",
        "xray:*",
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricStatistics"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowIAMSelfServiceOnly",
      "Effect": "Allow",
      "Action": [
        "iam:GetRole",
        "iam:ListRoles",
        "iam:PassRole"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyPrivilegeEscalation",
      "Effect": "Deny",
      "Action": [
        "iam:CreateUser",
        "iam:DeleteUser",
        "iam:AttachUserPolicy",
        "iam:CreateAccessKey",
        "iam:UpdateAccountPasswordPolicy",
        "organizations:*",
        "account:*"
      ],
      "Resource": "*"
    }
  ]
}
```

**Example 2: Delegation Policy — Allowing Developers to Create Roles with Boundaries**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowRoleCreationWithBoundary",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:PutRolePolicy",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:TagRole"
      ],
      "Resource": "arn:aws:iam::*:role/app-*",
      "Condition": {
        "StringEquals": {
          "iam:PermissionsBoundary": "arn:aws:iam::111122223333:policy/DeveloperBoundary"
        }
      }
    },
    {
      "Sid": "AllowPassRoleOnlyWithBoundary",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::*:role/app-*",
      "Condition": {
        "StringEquals": {
          "iam:PermissionsBoundary": "arn:aws:iam::111122223333:policy/DeveloperBoundary"
        }
      }
    },
    {
      "Sid": "DenyBoundaryModification",
      "Effect": "Deny",
      "Action": [
        "iam:DeleteRolePermissionsBoundary",
        "iam:CreatePolicyVersion",
        "iam:DeletePolicy",
        "iam:SetDefaultPolicyVersion"
      ],
      "Resource": "arn:aws:iam::111122223333:policy/DeveloperBoundary"
    }
  ]
}
```

**Example 3: Terraform — Creating a Role with a Permission Boundary**

```hcl
variable "boundary_policy_arn" {
  description = "ARN of the permission boundary policy"
  type        = string
  default     = "arn:aws:iam::111122223333:policy/DeveloperBoundary"
}

resource "aws_iam_role" "app_service_role" {
  name                 = "app-my-service-role"
  permissions_boundary = var.boundary_policy_arn   # <-- Boundary enforced

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    ManagedBy   = "developer-team"
    BoundaryApplied = "true"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.app_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
```

### c) ASCII Diagrams

**Diagram 1: Permission Boundary Effective Permission Intersection**

```
  ┌─────────────────────────────────────────────────────────────┐
  │          Effective Permissions = A ∩ B                      │
  └─────────────────────────────────────────────────────────────┘

  Identity-Based Policy (A)        Permission Boundary (B)
  ┌──────────────────────┐         ┌──────────────────────┐
  │                      │         │                      │
  │  s3:*                │         │  s3:*                │
  │  ec2:*               │         │  dynamodb:*          │
  │  iam:CreateRole      │         │  sqs:*               │
  │  dynamodb:*          │         │                      │
  │  route53:*           │         │                      │
  │                      │         │                      │
  └──────────────────────┘         └──────────────────────┘
           │                                  │
           └─────────────┬────────────────────┘
                         │
                         ▼
             Effective Permissions:
             ┌──────────────────┐
             │  s3:*            │  ← In BOTH policies
             │  dynamodb:*      │  ← In BOTH policies
             └──────────────────┘

  ec2:*, iam:CreateRole, route53:* → DENIED (not in boundary)
```

**Diagram 2: Delegation Model with Permission Boundary**

```
  ┌──────────────────────┐
  │  Platform / Security │
  │  Team (Admin)        │
  └──────────┬───────────┘
             │  1. Creates DeveloperBoundary policy
             │  2. Creates DeveloperDelegation policy
             │     (allows role creation IF boundary is attached)
             │  3. Assigns DeveloperDelegation to Dev team
             ▼
  ┌──────────────────────┐
  │  Developer Team      │
  └──────────┬───────────┘
             │  4. Creates app-my-service-role
             │     (MUST attach DeveloperBoundary)
             │
             ├─ Without boundary → DENIED by delegation policy
             │
             ▼
  ┌──────────────────────────────────────────┐
  │  app-my-service-role                      │
  │  ├── Identity Policy: s3:*, ec2:*, iam:* │
  │  └── Boundary: s3:*, dynamodb:*, sqs:*   │
  │                                           │
  │  Effective: s3:*, dynamodb:*, sqs:*       │
  │  (ec2:* and iam:* blocked by boundary)    │
  └──────────────────────────────────────────┘
```

---

## Detailed Explanations & Examples — Identity Federation

### a) Textual Deep Dive

Identity Federation is the practice of allowing externally managed identities to authenticate with AWS without creating native IAM users. This is essential for two reasons: it centralizes identity management in your existing IdP (Okta, Azure AD, PingFederate), and it eliminates the provisioning overhead of maintaining parallel IAM user accounts for every employee.

**SAML 2.0 Federation** works by having the IdP produce a signed XML assertion after authenticating the user. The assertion contains attributes (e.g., Department, Role) that map to IAM role ARNs. AWS validates the assertion using the IdP's public metadata, then calls `AssumeRoleWithSAML` to issue temporary credentials. The AWS Console SSO URL (`https://signin.aws.amazon.com/saml`) acts as the service provider endpoint.

**OIDC Federation** works differently: after authentication, the IdP issues a JWT (JSON Web Token). The client presents this JWT to STS via `AssumeRoleWithWebIdentity`. AWS fetches the IdP's public keys to validate the JWT signature, then checks the `aud` (audience) and `sub` (subject) claims against conditions in the role's trust policy. This is the mechanism behind Kubernetes IRSA (IAM Roles for Service Accounts), EKS Pod Identity, GitHub Actions OIDC, and Cognito Identity Pools.

**IAM Identity Center** provides enterprise-grade federation at scale: a single SAML source, SCIM-based user provisioning, permission sets that translate to roles in member accounts, and an access portal. It replaces manual per-account federation configuration with an organization-wide SSO solution. Attribute-based access control in Identity Center allows session tags to flow from IdP attributes, enabling fine-grained ABAC policies in member accounts.

### b) Practical Code Examples

**Example 1: Setting Up an OIDC Provider for GitHub Actions (AWS CLI)**

```bash
# Retrieve GitHub's OIDC thumbprint
THUMBPRINT=$(echo | openssl s_client \
  -servername token.actions.githubusercontent.com \
  -connect token.actions.githubusercontent.com:443 2>/dev/null \
  | openssl x509 -fingerprint -noout \
  | sed 's/://g' | awk -F= '{print tolower($2)}')

echo "Thumbprint: $THUMBPRINT"

# Create the OIDC Identity Provider
aws iam create-open-id-connect-provider \
  --url "https://token.actions.githubusercontent.com" \
  --client-id-list "sts.amazonaws.com" \
  --thumbprint-list "$THUMBPRINT"

# Create the federated role (trust policy in trust-policy.json)
aws iam create-role \
  --role-name GitHubActionsDeployRole \
  --assume-role-policy-document file://trust-policy.json \
  --max-session-duration 3600

# Attach deploy permissions
aws iam attach-role-policy \
  --role-name GitHubActionsDeployRole \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

**Example 2: Cognito Identity Pool for Mobile App Federation**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "us-east-1:EXAMPLE-POOL-ID"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "authenticated"
        }
      }
    }
  ]
}
```

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::user-uploads/${cognito-identity.amazonaws.com:sub}/*"
    }
  ]
}
```

> The `${cognito-identity.amazonaws.com:sub}` policy variable resolves to the user's unique Cognito identity ID, providing each user access to only their own S3 prefix.

**Example 3: Kubernetes IRSA (IAM Roles for Service Accounts) with Terraform**

```hcl
# Create OIDC provider for EKS cluster
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# IAM role for the Kubernetes service account
resource "aws_iam_role" "pod_s3_role" {
  name = "eks-pod-s3-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:my-namespace:my-service-account"
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

# Kubernetes ServiceAccount annotation
# kubectl annotate serviceaccount my-service-account \
#   eks.amazonaws.com/role-arn=<role_arn> -n my-namespace
```

### c) ASCII Diagrams

**Diagram 1: SAML 2.0 Federation Flow**

```
  User Browser           Corporate IdP (Okta/AD FS)        AWS
  ┌───────────┐          ┌────────────────────────┐    ┌──────────────┐
  │           │          │                        │    │              │
  │ 1. Access │          │                        │    │  IAM:        │
  │   AWS     │          │                        │    │  · SAML      │
  │  Console  │          │                        │    │    Provider  │
  │     │     │          │                        │    │  · Role      │
  │     │     │──2.Redirect to IdP───────────────►│    │    Mapping   │
  │     │     │          │                        │    │              │
  │     │     │          │ 3. Authenticate (MFA)  │    │              │
  │     │     │          │    user credentials    │    │              │
  │     │     │◄──4.SAML Assertion (signed XML)───┘    │              │
  │     │     │             (contains role ARN,         │              │
  │     │     │              attributes, expiry)        │              │
  │     │     │──5. POST to AWS /saml endpoint ────────►│              │
  │     │     │          │                             │ 6. Validate  │
  │     │     │          │                             │    SAML sig  │
  │     │     │          │                             │ 7. AssumeRole│
  │     │     │◄──8. Redirect with console session ────┘WithSAML     │
  │  AWS Console         │                             │              │
  │  (console.aws.amazon)           │                             │              │
  └───────────┘          └────────────────────────┘    └──────────────┘
```

**Diagram 2: IAM Identity Center Multi-Account Federation**

```
                Corporate IdP (Okta)
                 SAML 2.0 / SCIM
                        │
                        ▼
              ┌──────────────────┐
              │  IAM Identity    │
              │  Center          │
              │  (Management     │
              │   Account)       │
              └────────┬─────────┘
                       │
       ┌───────────────┼───────────────┐
       │               │               │
       ▼               ▼               ▼
  ┌─────────┐     ┌─────────┐     ┌─────────┐
  │ Dev     │     │ Staging │     │ Prod    │
  │ Account │     │ Account │     │ Account │
  │         │     │         │     │         │
  │ Role:   │     │ Role:   │     │ Role:   │
  │ Admin   │     │ Deploy  │     │ ReadOnly│
  └─────────┘     └─────────┘     └─────────┘

Legend:
  Permission Sets → IAM Roles in each member account
  SCIM → Automatic user/group sync from IdP
  Session tags from SAML attributes → ABAC in member accounts
```

---

## Detailed Explanations & Examples — Service Roles

### a) Textual Deep Dive

Service Roles represent the translation of least-privilege principles into machine-to-machine identity. Every AWS compute resource (EC2, Lambda, ECS task, Glue job, CodeBuild project) requires a role to make downstream API calls. The trust policy defines *which service* can assume the role; the permission policy defines *what that service can do*. Getting this right at scale requires a systematic approach.

For EC2, credentials are delivered via the Instance Metadata Service v2 (IMDSv2), which requires a session-oriented token exchange before credential retrieval—a security improvement over IMDSv1 that mitigated SSRF-based credential theft. You should enforce IMDSv2 in EC2 launch templates and instance profiles:

```bash
aws ec2 modify-instance-metadata-options \
  --instance-id i-1234567890abcdef0 \
  --http-tokens required \
  --http-put-response-hop-limit 1
```

For ECS and Fargate, there are two distinct roles per task definition: the **task execution role** (allows ECS to pull container images from ECR and retrieve secrets from Secrets Manager during task startup) and the **task role** (the application's identity for making AWS API calls at runtime). Conflating these two is a common mistake.

Service-Linked Roles (SLRs) are a special category: AWS creates and manages them automatically when you enable a service (e.g., `AWSServiceRoleForECS`, `AWSServiceRoleForAutoScaling`). Their trust policies and permission boundaries are locked by AWS—you cannot edit them directly—but you can view them and, in some cases, delete them if the service is no longer in use.

At the organizational level, use AWS Organizations SCPs to restrict which services can create roles with overly broad permissions, and use IAM Access Analyzer to continuously monitor for roles that allow cross-account or external principal access unintentionally.

### b) Practical Code Examples

**Example 1: Lambda Execution Role with Least-Privilege Permissions**

```hcl
resource "aws_iam_role" "lambda_exec" {
  name = "lambda-data-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda_permissions" {
  name = "lambda-data-processor-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:us-east-1:111122223333:log-group:/aws/lambda/data-processor:*"
      },
      {
        Sid    = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          "arn:aws:dynamodb:us-east-1:111122223333:table/Orders",
          "arn:aws:dynamodb:us-east-1:111122223333:table/Orders/index/*"
        ]
      },
      {
        Sid    = "SQSConsumeMessages"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "arn:aws:sqs:us-east-1:111122223333:order-processing-queue"
      },
      {
        Sid    = "DecryptWithCMK"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "arn:aws:kms:us-east-1:111122223333:key/mrk-abc123"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_permissions.arn
}
```

**Example 2: ECS Task Definition — Separating Task Role from Execution Role**

```json
{
  "family": "order-processor",
  "taskRoleArn": "arn:aws:iam::111122223333:role/ecs-order-processor-task-role",
  "executionRoleArn": "arn:aws:iam::111122223333:role/ecs-task-execution-role",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [
    {
      "name": "order-processor",
      "image": "111122223333.dkr.ecr.us-east-1.amazonaws.com/order-processor:latest",
      "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:111122223333:secret:prod/db/password"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/order-processor",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

> `taskRoleArn` = runtime app permissions (SQS, DynamoDB). `executionRoleArn` = ECS control plane permissions (ECR pull, Secrets Manager, CloudWatch Logs). Always keep these separate.

**Example 3: EC2 IMDSv2 Enforcement via Launch Template**

```bash
# Create a launch template enforcing IMDSv2
aws ec2 create-launch-template \
  --launch-template-name "secure-app-template" \
  --version-description "v1 - IMDSv2 enforced" \
  --launch-template-data '{
    "ImageId": "ami-0abcdef1234567890",
    "InstanceType": "t3.medium",
    "IamInstanceProfile": {
      "Name": "app-instance-profile"
    },
    "MetadataOptions": {
      "HttpTokens": "required",
      "HttpPutResponseHopLimit": 1,
      "HttpEndpoint": "enabled",
      "InstanceMetadataTags": "enabled"
    },
    "TagSpecifications": [{
      "ResourceType": "instance",
      "Tags": [
        {"Key": "Environment", "Value": "prod"},
        {"Key": "IMDSv2", "Value": "enforced"}
      ]
    }]
  }'

# Verify from inside the instance using IMDSv2
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

ROLE_CREDS=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/iam/security-credentials/app-role)

echo "$ROLE_CREDS" | jq '{AccessKeyId, Expiration}'
```

### c) ASCII Diagrams

**Diagram 1: Service Role Architecture for ECS Fargate**

```
  ┌─────────────────────────────────────────────────────────────────┐
  │                   ECS Fargate Task Lifecycle                    │
  └─────────────────────────────────────────────────────────────────┘

  ECS Control Plane                Task Runtime (Container)
  ┌─────────────────────┐          ┌──────────────────────────┐
  │                     │          │                          │
  │  Task Execution     │          │  Task Role               │
  │  Role               │          │  (app-task-role)         │
  │  ┌───────────────┐  │          │  ┌─────────────────────┐ │
  │  │ · ECR:Pull    │  │ 1.Pull   │  │ · dynamodb:GetItem  │ │
  │  │   image       │──┼──image──►│  │ · sqs:Receive       │ │
  │  │ · Logs:Create │  │          │  │ · s3:GetObject      │ │
  │  │   streams     │  │ 2.Fetch  │  └──────────┬──────────┘ │
  │  │ · Secrets:    │──┼──secret─►│             │            │
  │  │   GetValue    │  │          │             │ 3. App makes│
  │  └───────────────┘  │          │             │    API calls│
  │                     │          │             ▼            │
  └─────────────────────┘          │  ┌─────────────────────┐ │
                                   │  │  AWS Services:      │ │
                                   │  │  DynamoDB, SQS, S3  │ │
                                   │  └─────────────────────┘ │
                                   └──────────────────────────┘

  Key: TaskExecutionRole = ECS infrastructure access
       TaskRole = Application runtime access
```

**Diagram 2: EC2 IMDSv2 Credential Retrieval**

```
  EC2 Instance                           AWS Metadata Service
  ┌────────────────────────────┐         ┌──────────────────────┐
  │                            │         │                      │
  │  Application Code          │         │  169.254.169.254     │
  │  ┌──────────────────────┐  │         │                      │
  │  │ 1. PUT /latest/      │  │         │ IMDSv2 Requirements: │
  │  │    api/token         │──┼────────►│ · Session token      │
  │  │    TTL: 21600s       │  │         │   required (v2)      │
  │  │                      │  │◄────────┤ · Hop limit = 1      │
  │  │ 2. Receive token     │  │  Token  │   (blocks SSRF)      │
  │  └────────────┬─────────┘  │         │                      │
  │               │            │         │                      │
  │  ┌────────────▼─────────┐  │         │                      │
  │  │ 3. GET /meta-data/   │  │         │                      │
  │  │    iam/security-     │──┼────────►│                      │
  │  │    credentials/role  │  │         │                      │
  │  │    (with token hdr)  │  │◄────────┤                      │
  │  │                      │  │  Creds  │                      │
  │  │ 4. Use temp creds    │  │ (JSON)  │                      │
  │  │    for AWS API calls │  │         │                      │
  │  └──────────────────────┘  │         │                      │
  └────────────────────────────┘         └──────────────────────┘
```

---

## Hands-On Scenarios — IAM Users, Groups, Roles & Policies

### Scenario 1: Bootstrap a Multi-Team AWS Account with Role-Based Access

**Objective**: Set up IAM groups for DevOps, Developer, and ReadOnly teams, with appropriate managed policies and enforce MFA.

**Steps**:

```bash
# 1. Create IAM groups
aws iam create-group --group-name DevOps
aws iam create-group --group-name Developers
aws iam create-group --group-name ReadOnly

# 2. Attach policies to groups
aws iam attach-group-policy \
  --group-name DevOps \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

aws iam attach-group-policy \
  --group-name Developers \
  --policy-arn arn:aws:iam::aws:policy/AWSCodeCommitPowerUser

aws iam attach-group-policy \
  --group-name ReadOnly \
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

# 3. Create an MFA enforcement policy
cat > mfa-enforce.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyWithoutMFA",
      "Effect": "Deny",
      "NotAction": [
        "iam:CreateVirtualMFADevice",
        "iam:EnableMFADevice",
        "iam:GetUser",
        "iam:ListMFADevices",
        "iam:ListVirtualMFADevices",
        "iam:ResyncMFADevice",
        "sts:GetSessionToken"
      ],
      "Resource": "*",
      "Condition": {
        "BoolIfExists": {
          "aws:MultiFactorAuthPresent": "false"
        }
      }
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name EnforceMFA \
  --policy-document file://mfa-enforce.json

# Attach to all groups
for GROUP in DevOps Developers ReadOnly; do
  aws iam attach-group-policy \
    --group-name "$GROUP" \
    --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/EnforceMFA
done
```

**Expected Outcome**: All group members must enroll MFA before performing any meaningful AWS actions. Without MFA, only self-service MFA enrollment APIs are accessible.

**Troubleshooting**:
- "AccessDenied on iam:EnableMFADevice" → Ensure the MFA policy's `NotAction` includes `iam:EnableMFADevice`.
- Users locked out entirely → Check that `sts:GetSessionToken` is in the `NotAction` list so users can get an MFA session.

---

### Scenario 2: Implementing ABAC with IAM Roles and Tags

**Objective**: Engineers tagged `Environment=dev` can only manage EC2 instances tagged `Environment=dev`.

**Steps**:

```bash
# 1. Create the ABAC policy
cat > abac-ec2-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["ec2:StartInstances","ec2:StopInstances","ec2:DescribeInstances"],
    "Resource": "*",
    "Condition": {
      "StringEquals": {
        "ec2:ResourceTag/Environment": "${aws:PrincipalTag/Environment}"
      }
    }
  }]
}
EOF

aws iam create-policy --policy-name ABAC-EC2-Env --policy-document file://abac-ec2-policy.json

# 2. Create the role and tag it
aws iam create-role --role-name dev-engineer-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::111122223333:root"},"Action":"sts:AssumeRole"}]}'

aws iam tag-role --role-name dev-engineer-role \
  --tags Key=Environment,Value=dev

# 3. Tag EC2 instances
aws ec2 create-tags --resources i-1234567890abcdef0 \
  --tags Key=Environment,Value=dev
```

**Expected Outcome**: The `dev-engineer-role` can only start/stop EC2 instances tagged `Environment=dev`. Attempting to modify a `prod` instance returns `AccessDenied`.

**Troubleshooting**:
- "Policy does not apply" → Verify `aws:PrincipalTag/Environment` is resolved; the role must be tagged, not just the user.
- Condition not matching → Use `aws iam simulate-principal-policy` with `--context-entries` to test ABAC conditions.

---

### Scenario 3: Auditing Unused Permissions with IAM Access Analyzer

**Steps**:

```bash
# 1. Create an Access Analyzer for the account
aws accessanalyzer create-analyzer \
  --analyzer-name account-analyzer \
  --type ACCOUNT

# 2. Generate a policy based on CloudTrail access activity
aws accessanalyzer start-policy-generation \
  --policy-generation-details '{"principalArn":"arn:aws:iam::111122223333:role/my-role"}' \
  --cloud-trail-details '{
    "trails": [{"cloudTrailArn":"arn:aws:cloudtrail:us-east-1:111122223333:trail/management-events","allRegions":true}],
    "accessRole": "arn:aws:iam::111122223333:role/AccessAnalyzerRole",
    "startTime": "2026-01-01T00:00:00Z",
    "endTime":   "2026-03-01T00:00:00Z"
  }'

# 3. List findings (external cross-account access)
aws accessanalyzer list-findings \
  --analyzer-arn arn:aws:accessanalyzer:us-east-1:111122223333:analyzer/account-analyzer
```

**Expected Outcome**: Access Analyzer produces a policy recommendation containing only the actions actually used in the trailing period, allowing you to right-size existing over-permissive roles.

---

## Hands-On Scenarios — STS

### Scenario 1: Multi-Account Deployment Pipeline Using Role Chaining

**Objective**: A CI/CD role in the Tooling account assumes a deployment role in each target account sequentially.

```bash
#!/usr/bin/env bash
# deploy-multi-account.sh

set -euo pipefail

TOOLING_ACCOUNT="444455556666"
ACCOUNTS=("111122223333" "777788889999")
ROLE_NAME="CrossAccountDeployRole"
REGION="us-east-1"

for TARGET_ACCOUNT in "${ACCOUNTS[@]}"; do
  echo "Deploying to account: $TARGET_ACCOUNT"

  CREDS=$(aws sts assume-role \
    --role-arn "arn:aws:iam::${TARGET_ACCOUNT}:role/${ROLE_NAME}" \
    --role-session-name "pipeline-deploy-$(date +%s)" \
    --duration-seconds 1800 \
    --query 'Credentials' \
    --output json)

  export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | jq -r '.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r '.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(echo "$CREDS" | jq -r '.SessionToken')

  # Verify we are now in the correct account
  IDENTITY=$(aws sts get-caller-identity)
  echo "Operating as: $IDENTITY"

  # Deploy CloudFormation stack
  aws cloudformation deploy \
    --template-file infra/main.cfn.yaml \
    --stack-name "app-stack-${TARGET_ACCOUNT}" \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --region "$REGION"

  # Clear credentials before next iteration
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
  echo "Completed deployment to $TARGET_ACCOUNT"
done
```

**Expected Outcome**: The pipeline deploys to each target account using temporary credentials, with no long-lived access keys stored anywhere.

**Troubleshooting**:
- `AccessDenied` on AssumeRole → Ensure the tooling account role ARN is in the target role's trust policy.
- "Cannot assume role — maximum session duration exceeded" → Role's `MaxSessionDuration` must be >= requested duration.

---

### Scenario 2: Enforcing MFA for Sensitive Operations via STS

```bash
# 1. User obtains MFA-enforced session token
MFA_ARN="arn:aws:iam::111122223333:mfa/alice"
MFA_TOKEN="123456"  # Current TOTP code

CREDS=$(aws sts get-session-token \
  --serial-number "$MFA_ARN" \
  --token-code "$MFA_TOKEN" \
  --duration-seconds 7200 \
  --query 'Credentials' \
  --output json)

export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | jq -r '.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r '.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$CREDS" | jq -r '.SessionToken')

# 2. Now the user can perform MFA-protected operations
# e.g., deleting a production S3 bucket (protected by MFA condition)
aws s3 rb s3://my-critical-bucket --force
```

**Troubleshooting**: If the MFA condition on the target policy uses `aws:MultiFactorAuthPresent` and the user still gets denied after `GetSessionToken`, ensure the session's MFA status is being passed correctly by checking `aws sts get-caller-identity` includes the MFA ARN in the ARN string.

---

### Scenario 3: Detecting and Alerting on Unauthorized Role Assumption via CloudTrail

```python
# lambda_sts_monitor.py — triggered by EventBridge rule on AssumeRole events
import json
import boto3
import os

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
ALLOWED_SESSION_NAMES = {"ci-pipeline", "terraform", "scheduled-maintenance"}

def lambda_handler(event, context):
    detail = event.get("detail", {})
    event_name = detail.get("eventName", "")

    if event_name not in ("AssumeRole", "AssumeRoleWithWebIdentity"):
        return

    role_arn         = detail.get("requestParameters", {}).get("roleArn", "")
    session_name     = detail.get("requestParameters", {}).get("roleSessionName", "")
    source_ip        = detail.get("sourceIPAddress", "")
    user_agent       = detail.get("userAgent", "")
    error_code       = detail.get("errorCode", "")

    # Alert on suspicious patterns
    alerts = []

    if error_code == "AccessDenied":
        alerts.append(f"FAILED AssumeRole attempt on {role_arn} from IP {source_ip}")

    if session_name not in ALLOWED_SESSION_NAMES and "prod" in role_arn.lower():
        alerts.append(
            f"UNAUTHORIZED session name '{session_name}' used for production role {role_arn}"
        )

    if alerts:
        sns = boto3.client("sns")
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="[SECURITY] Suspicious STS AssumeRole Activity",
            Message=json.dumps({
                "alerts": alerts,
                "event_detail": detail
            }, indent=2)
        )

    return {"statusCode": 200}
```

---

## Hands-On Scenarios — Permission Boundaries

### Scenario 1: Platform Team Implements Safe Developer IAM Delegation

**Steps**:

```bash
# 1. Platform team creates the boundary policy
aws iam create-policy \
  --policy-name DeveloperBoundary \
  --policy-document file://developer-boundary.json

BOUNDARY_ARN=$(aws iam list-policies \
  --query "Policies[?PolicyName=='DeveloperBoundary'].Arn" \
  --output text)

# 2. Platform team creates the developer delegation policy
cat > developer-delegation.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowRoleCreateWithBoundary",
      "Effect": "Allow",
      "Action": ["iam:CreateRole","iam:AttachRolePolicy","iam:PutRolePolicy","iam:TagRole"],
      "Resource": "arn:aws:iam::*:role/app-*",
      "Condition": {"StringEquals": {"iam:PermissionsBoundary": "$BOUNDARY_ARN"}}
    },
    {
      "Sid": "DenyBoundaryAlteration",
      "Effect": "Deny",
      "Action": ["iam:DeleteRolePermissionsBoundary","iam:CreatePolicyVersion","iam:DeletePolicy"],
      "Resource": ["$BOUNDARY_ARN","arn:aws:iam::*:role/app-*"]
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name DeveloperDelegation \
  --policy-document file://developer-delegation.json

# 3. Attach delegation policy to the Developer group
aws iam attach-group-policy \
  --group-name Developers \
  --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/DeveloperDelegation
```

**Expected Outcome**: Developers can create IAM roles with the `app-` prefix only if the boundary is attached. Attempts to create roles without the boundary or remove the boundary from existing roles are denied.

**Troubleshooting**:
- "Developer can still create admin role" → Verify the Condition key is `iam:PermissionsBoundary` (not `iam:PassedToService`).
- "Cannot attach boundary" → Developer needs `iam:PutRolePermissionsBoundary` explicitly allowed.

---

### Scenario 2: Verifying Boundary Enforcement

```bash
# Test: try creating a role WITHOUT the boundary (should fail)
aws iam create-role \
  --role-name app-test-no-boundary \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  # Expected output: An error occurred (AccessDenied)

# Test: create a role WITH the boundary (should succeed)
aws iam create-role \
  --role-name app-test-with-boundary \
  --permissions-boundary arn:aws:iam::111122223333:policy/DeveloperBoundary \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

# Verify effective permissions (boundary limits ec2:* even if policy allows it)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::111122223333:role/app-test-with-boundary \
  --action-names ec2:DescribeInstances s3:GetObject \
  --query 'EvaluationResults[*].{Action:EvalActionName,Decision:EvalDecision}'
```

---

## Hands-On Scenarios — Identity Federation

### Scenario 1: Configure SAML Federation with Okta

**Steps**:

```bash
# 1. Download Okta SAML metadata XML from Okta Admin Console
# (Setup > Sign On > View SAML Setup Instructions > Identity Provider metadata)

# 2. Create the SAML Provider in AWS
aws iam create-saml-provider \
  --name OktaSAMLProvider \
  --saml-metadata-document file://okta-metadata.xml

SAML_ARN=$(aws iam list-saml-providers \
  --query "SAMLProviderList[?contains(Arn,'OktaSAMLProvider')].Arn" \
  --output text)

# 3. Create the federated role
cat > saml-trust.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Federated": "$SAML_ARN"},
    "Action": "sts:AssumeRoleWithSAML",
    "Condition": {
      "StringEquals": {
        "SAML:aud": "https://signin.aws.amazon.com/saml"
      }
    }
  }]
}
EOF

aws iam create-role \
  --role-name OktaFederatedAdminRole \
  --assume-role-policy-document file://saml-trust.json \
  --max-session-duration 43200

aws iam attach-role-policy \
  --role-name OktaFederatedAdminRole \
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
```

**Expected Outcome**: Okta users whose SAML assertion references this role ARN are redirected to the AWS Console with ReadOnly access.

**Troubleshooting**:
- "Invalid SAML response" → Confirm the Okta application's audience and ACS URL match AWS endpoints.
- "No role found in assertion" → Okta must send the `https://aws.amazon.com/SAML/Attributes/Role` attribute with `roleARN,providerARN` format.

---

### Scenario 2: Kubernetes IRSA Setup for Pod-Level AWS Access

```bash
# 1. Get EKS OIDC issuer URL
OIDC_URL=$(aws eks describe-cluster \
  --name my-cluster \
  --query "cluster.identity.oidc.issuer" \
  --output text)

OIDC_HOST=$(echo "$OIDC_URL" | sed 's|https://||')

# 2. Create OIDC provider (if not already created by eksctl)
aws iam create-open-id-connect-provider \
  --url "$OIDC_URL" \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list "$(echo | openssl s_client -connect "${OIDC_HOST}:443" 2>/dev/null | openssl x509 -fingerprint -noout | sed 's/://g' | awk -F= '{print tolower($2)}')"

# 3. Create role for service account
cat > irsa-trust.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Federated": "arn:aws:iam::111122223333:oidc-provider/${OIDC_HOST}"},
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "${OIDC_HOST}:sub": "system:serviceaccount:production:order-service",
        "${OIDC_HOST}:aud": "sts.amazonaws.com"
      }
    }
  }]
}
EOF

aws iam create-role --role-name eks-order-service-role \
  --assume-role-policy-document file://irsa-trust.json

# 4. Annotate Kubernetes ServiceAccount
kubectl annotate serviceaccount order-service \
  -n production \
  eks.amazonaws.com/role-arn=arn:aws:iam::111122223333:role/eks-order-service-role
```

---

## Hands-On Scenarios — Service Roles

### Scenario 1: Secure CodePipeline with Cross-Account Deployment Role

```bash
# In TARGET account — create deployment role trusted by the pipeline account
cat > codepipeline-trust.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "AWS": "arn:aws:iam::444455556666:role/CodePipelineServiceRole"
    },
    "Action": "sts:AssumeRole"
  }]
}
EOF

aws iam create-role \
  --role-name CrossAccountDeployRole \
  --assume-role-policy-document file://codepipeline-trust.json

aws iam attach-role-policy \
  --role-name CrossAccountDeployRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess  # Scope down in production!

# In PIPELINE account — CodePipeline service role needs sts:AssumeRole
cat > pipeline-role-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::111122223333:role/CrossAccountDeployRole"
  }]
}
EOF
```

---

### Scenario 2: Enforcing IMDSv2 Across an Entire AWS Account

```bash
# Set account-level default for new instances
aws ec2 modify-instance-metadata-defaults \
  --http-tokens required \
  --http-put-response-hop-limit 2 \
  --instance-metadata-tags enabled \
  --region us-east-1

# Remediate existing non-compliant instances
aws ec2 describe-instances \
  --filters "Name=metadata-options.http-tokens,Values=optional" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text | tr '\t' '\n' | while read -r INSTANCE_ID; do
    echo "Patching instance: $INSTANCE_ID"
    aws ec2 modify-instance-metadata-options \
      --instance-id "$INSTANCE_ID" \
      --http-tokens required \
      --http-put-response-hop-limit 1
done

# AWS Config rule to detect non-compliance
aws configservice put-config-rule \
  --config-rule '{
    "ConfigRuleName": "ec2-imdsv2-check",
    "Source": {
      "Owner": "AWS",
      "SourceIdentifier": "EC2_IMDSV2_CHECK"
    }
  }'
```

---

## Most Asked Interview Questions with Answers

---

**Q1: IAM Policy Types and Evaluation**

- **Question**: Explain the different types of IAM policies in AWS and how they interact during policy evaluation. Walk me through a scenario where a principal is denied access despite having an explicit Allow in their identity policy.
- **Expected Level**: Senior
- **Difficulty**: Hard
- **Answer**: AWS IAM has six policy types: identity-based policies (managed and inline, attached to users/groups/roles), resource-based policies (attached to resources like S3, KMS, Lambda), permission boundaries (ceiling on identity-based policies), session policies (inline policies passed at AssumeRole time), SCPs (Organization-level guardrails), and ACLs (legacy, for cross-account S3/cross-account resource access). Evaluation occurs in the following order: AWS first checks for an explicit Deny in any policy (this immediately overrides everything). Then it checks SCPs—if the organization doesn't allow an action, it cannot proceed. Then resource-based policies are checked for cross-account access. Then identity-based policies are checked. Then permission boundaries are applied (the action must fall within the boundary). Finally, session policies are evaluated. A concrete denial scenario: an engineer's identity policy has `s3:DeleteBucket` allowed. However, the AWS Organization's SCP for that account explicitly denies `s3:DeleteBucket` (to prevent accidental deletion of compliance buckets). Despite the explicit Allow in the identity policy, the SCP Deny wins. Another scenario: a Lambda role has `dynamodb:*` in its identity policy, but its permission boundary only includes `s3:*` and `sqs:*`. Any DynamoDB call will be denied because `dynamodb:*` is not within the boundary, even though the identity policy allows it.
- **Follow-up Questions**:
  1. How does cross-account access work when both a resource-based policy and an identity policy must allow the action?
  2. Does a permission boundary affect access from resource-based policies?
  3. What happens when an SCP uses `NotAction` instead of `Action`?
- **Key Points to Highlight**:
  - Explicit Deny always wins, at any policy layer.
  - Boundaries do NOT grant permissions; they restrict maximum possible permissions.
  - Cross-account: both identity policy (in source account) AND resource-based policy (in target account) must allow.
  - SCPs apply to all principals in the OU except the management account.
- **Example Answer**:

```python
# Simulate policy to detect the exact evaluation result
import boto3

iam = boto3.client("iam")
response = iam.simulate_principal_policy(
    PolicySourceArn="arn:aws:iam::111122223333:role/my-lambda-role",
    ActionNames=["dynamodb:GetItem", "s3:GetObject"],
    ResourceArns=["arn:aws:dynamodb:us-east-1:111122223333:table/Orders",
                  "arn:aws:s3:::my-bucket/*"],
)
for result in response["EvaluationResults"]:
    print(f"{result['EvalActionName']}: {result['EvalDecision']}")
    if result.get("MatchedStatements"):
        for stmt in result["MatchedStatements"]:
            print(f"  Matched: {stmt['SourcePolicyId']}")
```

- **What Interviewers Are Really Asking**: Can you reason through complex, multi-layer policy interactions without resorting to trial and error? Do you understand that "allow" alone is not sufficient in enterprise multi-policy environments?

---

**Q2: STS and Credential Management**

- **Question**: How would you architect a CI/CD system that deploys to 20 AWS accounts without any long-lived access keys? Describe the full authentication and authorization chain.
- **Expected Level**: Senior
- **Difficulty**: Hard
- **Answer**: The architecture uses AWS IAM OIDC federation with the CI/CD platform (GitHub Actions, GitLab, or Jenkins). The CI/CD platform acts as an OIDC Identity Provider. Each pipeline run requests a short-lived JWT from the platform's built-in OIDC endpoint, then exchanges it for AWS temporary credentials by calling `sts:AssumeRoleWithWebIdentity` against a "CI Hub" role in a central tooling account. The trust policy on the Hub role restricts assumptions to specific repositories and branches (e.g., `sub` claim like `repo:my-org/my-repo:ref:refs/heads/main`). The Hub role has only `sts:AssumeRole` permission for a list of deployment role ARNs in each of the 20 target accounts. In each target account, a deployment role's trust policy allows assumption from the Hub role ARN in the tooling account. Each deployment role carries only the permissions needed for that account's workloads. For parallel deployments, the pipeline obtains separate STS credentials for each target account separately. Credentials expire in 15–60 minutes. Session names include the commit SHA and pipeline run ID for audit traceability in CloudTrail. No access keys are stored anywhere—not in environment variables, not in secrets managers, not in S3. The entire trust chain: OIDC JWT → Hub role (STS AssumeRoleWithWebIdentity) → per-account deploy role (STS AssumeRole).
- **Follow-up Questions**:
  1. How do you prevent one repository from assuming the role intended for a different repository?
  2. What happens if the CI platform's OIDC endpoint is temporarily unavailable?
  3. How do you handle the 1-hour maximum session duration for very long deployments?
- **Key Points to Highlight**:
  - OIDC eliminates secrets from the CI system entirely.
  - `sub` claim scoping to specific repos/branches is non-negotiable.
  - Role chaining (Hub → target) creates a clear audit trail.
  - Session names with metadata aid CloudTrail querying.
  - Deployment roles in target accounts trust only the Hub role ARN, not the entire source account.

---

**Q3: Permission Boundaries and Privilege Escalation Prevention**

- **Question**: A developer in your organization has `iam:CreateRole` and `iam:AttachRolePolicy` but should not be able to escalate their own privileges. How do you prevent this using permission boundaries, and what common bypass attempts should you guard against?
- **Expected Level**: Senior
- **Difficulty**: Hard
- **Answer**: The core problem is that `iam:CreateRole` + `iam:AttachRolePolicy` alone allows a user to create a role with `AdministratorAccess` and then assume it—gaining full account access. Permission boundaries address this by requiring that any role created by the developer must carry a boundary that caps its maximum permissions below AdministratorAccess. The delegation policy enforces this with a Condition: `iam:PermissionsBoundary` must equal the boundary ARN on all `iam:CreateRole` calls. Without this condition, the CreateRole call is denied. Guard against these bypass attempts: (1) Creating a new policy version of the boundary policy — deny `iam:CreatePolicyVersion` on the boundary ARN. (2) Deleting and recreating the boundary policy — deny `iam:DeletePolicy` on the boundary ARN. (3) Setting a different default policy version — deny `iam:SetDefaultPolicyVersion`. (4) Removing the boundary from the role — deny `iam:DeleteRolePermissionsBoundary`. (5) Creating a user instead of a role — ensure the developer lacks `iam:CreateUser`, `iam:CreateAccessKey`. (6) Passing a non-boundary role to Lambda — include `iam:PassRole` with a boundary condition. (7) Using CloudFormation to create roles — the CloudFormation execution role itself must also carry the boundary.
- **Follow-up Questions**:
  1. How does this interact when the developer uses CDK or Terraform to create roles?
  2. Can a permission boundary prevent access to a resource granted by a resource-based policy?
  3. How would AWS Organizations SCPs add another layer here?
- **Key Points to Highlight**:
  - Boundaries are not self-enforcing — the delegation policy's `Condition` is what creates the enforcement.
  - Denying boundary modification is as critical as requiring it on creation.
  - `iam:PassRole` must also be conditioned on boundary presence.
  - Test with `iam:simulate-principal-policy` after implementing.

---

**Q4: Identity Federation Deep Dive**

- **Question**: Walk me through the technical differences between SAML 2.0 and OIDC federation in AWS. When would you choose one over the other, and what are the security considerations unique to each?
- **Expected Level**: Senior
- **Difficulty**: Medium
- **Answer**: SAML 2.0 is an XML-based protocol designed for enterprise web SSO. The authentication assertion is a signed XML document containing attribute statements, name identifiers, and role mappings. The IdP (e.g., Okta, AD FS) initiates or responds to authentication, produces the signed assertion, and redirects the user's browser to the AWS SAML endpoint (`https://signin.aws.amazon.com/saml`). AWS validates the XML signature against the IdP metadata certificate stored in an IAM SAML Provider. The mapped IAM role must include `sts:AssumeRoleWithSAML` in its trust policy. SAML is primarily browser-based and not well-suited for machine-to-machine flows. OIDC, by contrast, is a JSON/JWT based protocol built on OAuth 2.0. The OIDC flow involves obtaining a JWT from the IdP, then calling `sts:AssumeRoleWithWebIdentity` with that JWT. AWS validates the JWT signature using the OIDC provider's public keys (fetched from the `jwks_uri` endpoint). OIDC is extremely flexible: it works for browser flows (Cognito), machine-to-machine (GitHub Actions, GitLab CI), and Kubernetes workloads (IRSA, EKS Pod Identity). Security considerations: For SAML, risk lies in the XML signature wrapping attacks—ensure IdP is configured to use `enveloped` signatures. The SAML metadata certificate must be rotated when the IdP certificate expires. For OIDC, the trust policy conditions on `aud` and `sub` must be tight; a loose `StringLike` on `sub` can allow any repo in an organization to assume the role. Also verify the OIDC provider thumbprint is kept current as certificates rotate.
- **Follow-up Questions**:
  1. How does IAM Identity Center unify SAML and OIDC federation?
  2. What is the audience (`aud`) claim validation, and why is it important?
  3. How does IRSA differ from the EKS Pod Identity agent introduced in 2023?
- **Key Points to Highlight**:
  - SAML = XML assertions, browser redirect flow, enterprise IdP.
  - OIDC = JWT, programmatic flows, CI/CD and Kubernetes native.
  - Identity Center abstracts the federation complexity at the organization level.
  - Both require tight trust policy Conditions to prevent unauthorized assumption.

---

**Q5: Service Role Least Privilege Design**

- **Question**: How do you design least-privilege IAM roles for a microservices architecture running on ECS Fargate, where 15 services need varying levels of access to DynamoDB, SQS, S3, and Secrets Manager?
- **Expected Level**: Senior
- **Difficulty**: Medium
- **Answer**: The correct approach combines role-per-service isolation, resource ARN scoping, and infrastructure-as-code policy management. Each of the 15 services gets its own ECS task role (not a shared role). The principle of least privilege at the service level: a service that only reads from a DynamoDB table gets `dynamodb:GetItem,Query,Scan` on that table's specific ARN and its indexes — not `dynamodb:*` and not access to other tables. For SQS, a producer service gets only `sqs:SendMessage` on specific queue ARNs; a consumer gets `sqs:ReceiveMessage,DeleteMessage,GetQueueAttributes`. For Secrets Manager, scope to specific secret ARN patterns: `arn:aws:secretsmanager:region:account:secret:service-name/*`. Separate the task execution role (ECR pull, logs, secret injection at startup) from the task role (runtime API calls). Use Terraform modules or CDK constructs to template role creation, ensuring consistency and auditability. Implement tags (`Service=order-processor`, `Environment=prod`) and use IAM Access Analyzer policy generation on CloudTrail logs after a burn-in period to identify unused permissions and further tighten policies. Regularly run the Access Analyzer's "Unused Access" report to detect roles that have not used certain permissions in 90 days. For KMS-encrypted resources, add the specific CMK ARN rather than the wildcard resource.
- **Follow-up Questions**:
  1. How do you handle a service that needs to invoke another internal service's API (service-to-service auth)?
  2. How do you manage 15 separate task roles without policy drift?
  3. What's the difference between the ECS task execution role and the task role?
- **Key Points to Highlight**:
  - One role per service — never share task roles across services.
  - Scope to specific resource ARNs, not wildcards.
  - Separate task role from task execution role.
  - Use IaC modules to enforce consistent, auditable policies.
  - Access Analyzer policy generation as a right-sizing tool.

---

**Q6: STS ExternalId and Confused Deputy**

- **Question**: What is the confused deputy problem in AWS IAM, and how does the `ExternalId` condition in STS prevent it?
- **Expected Level**: Mid/Senior
- **Difficulty**: Medium
- **Answer**: The confused deputy problem occurs in a multi-tenant SaaS scenario. Suppose a SaaS vendor (Vendor A) needs cross-account access to customer AWS accounts. Vendor A sets up a shared IAM role ARN in their system. If a malicious customer (Customer B) discovers the shared role ARN of Customer A, they can instruct Vendor A's service to assume *Customer A's* role using Vendor A's trusted identity — because the trust policy only checks that the caller is Vendor A, not which customer they are acting on behalf of. `ExternalId` solves this. When Customer A grants access to Vendor A, they generate a unique, random ExternalId value known only to Customer A and Vendor A, and embed it in the role's trust policy as a Condition: `StringEquals: sts:ExternalId: unique-secret-xyz`. Vendor A stores this ExternalId in their backend, associated with Customer A's account. When Vendor A makes an AssumeRole call for Customer A, they include `--external-id unique-secret-xyz`. The STS call succeeds only if the ExternalId matches. Customer B cannot guess or reuse Customer A's ExternalId, so even if Customer B knows Customer A's role ARN, they cannot instruct Vendor A's service to assume it. ExternalId is only useful when your role is being assumed by a third-party service. For internal cross-account roles (e.g., your own tooling account assuming your own prod role), ExternalId is not needed — use a specific role ARN condition in the trust policy instead.
- **Follow-up Questions**:
  1. Is ExternalId a secret? Should it be treated as one?
  2. How does this differ from using `aws:SourceAccount` or `aws:SourceArn` conditions?
  3. Can ExternalId be rotated, and if so, how?
- **Key Points to Highlight**:
  - ExternalId = shared secret between the customer and the trusted third party.
  - Without ExternalId, the trust policy only validates the *caller*, not who they're acting for.
  - ExternalId should be unique per customer and non-guessable.
  - AWS recommends UUIDs or cryptographically random strings as ExternalId values.

---

**Q7: IAM Access Analyzer**

- **Question**: Describe how you would use IAM Access Analyzer in a production environment to maintain a least-privilege security posture over time.
- **Expected Level**: Senior
- **Difficulty**: Medium
- **Answer**: IAM Access Analyzer serves three primary functions in production: external access analysis, policy validation, and policy generation from CloudTrail. For external access analysis, deploy an Organization-level analyzer in the management account with a zone of trust set to the entire organization. This surfaces any IAM roles, S3 buckets, KMS keys, SQS queues, or Lambda functions that are accessible from outside the organization (unexpected cross-account or public access). Integrate analyzer findings into your SIEM or ticketing system via EventBridge rules that trigger Lambda or SNS on new findings. For policy validation, use it in CI/CD pipelines to validate new IAM policy documents using `aws accessanalyzer validate-policy`. This catches policy grammar errors, overly broad `*` resources, missing conditions, and security warnings without deploying to production. For policy generation, enable CloudTrail, then after a representative burn-in period (30–90 days), use `start-policy-generation` against a role's CloudTrail activity. The resulting least-privilege policy recommendation contains only the actions actually invoked—use this to replace overly broad managed policies. Automate findings remediation: use AWS Config + Config Rules (`IAM_USER_NO_POLICIES_CHECK`, `IAM_ROOT_ACCESS_KEY_CHECK`) alongside Access Analyzer findings for a comprehensive posture. Schedule quarterly access reviews using AWS Security Hub which aggregates Access Analyzer findings with other security signals.
- **Follow-up Questions**:
  1. What is the difference between an account-level and organization-level analyzer?
  2. How does Access Analyzer handle resource-based policies vs. identity-based policies?
  3. What's the unused access feature, and how does it differ from policy generation?
- **Key Points to Highlight**:
  - Organization-level analyzer required for true cross-account coverage.
  - Policy validation in CI before deployment prevents security regressions.
  - CloudTrail-based policy generation requires sufficient activity duration.
  - EventBridge integration for automated remediation workflows.

---

**Q8: IAM Roles for Kubernetes (IRSA vs. EKS Pod Identity)**

- **Question**: Compare AWS IRSA (IAM Roles for Service Accounts) with the newer EKS Pod Identity mechanism. What are the architectural differences, and which would you choose for new workloads?
- **Expected Level**: Senior
- **Difficulty**: Hard
- **Answer**: IRSA (IAM Roles for Service Accounts) was the original Kubernetes-to-AWS IAM integration. In IRSA, EKS acts as an OIDC provider. Each service account in Kubernetes is annotated with an IAM role ARN. When a pod starts, the EKS webhook injects the OIDC token and role ARN as environment variables. The application SDK uses these to call `AssumeRoleWithWebIdentity`, exchanging the Kubernetes-issued OIDC JWT for AWS temporary credentials. The trust policy condition must exactly match the Kubernetes service account's namespace and name. EKS Pod Identity (GA in November 2023) is a newer mechanism that eliminates the need for managing OIDC providers and trust policy conditions. Instead, you create a Pod Identity Association that binds an EKS cluster + Kubernetes namespace + service account to an IAM role. The EKS Pod Identity Agent (a DaemonSet installed via EKS add-on) intercepts credential requests from pods and exchanges them for AWS credentials via a new IMDS-like interface. The IAM role's trust policy only needs to allow `pods.eks.amazonaws.com` — no sub claim conditions required. This dramatically simplifies multi-cluster and multi-account scenarios. For new workloads, choose EKS Pod Identity: it's simpler to configure, doesn't require per-cluster OIDC provider management, supports cross-account role assumption natively, and the trust policy is cluster-agnostic. IRSA remains valid for environments requiring compatibility with older EKS versions or specific OIDC features.
- **Follow-up Questions**:
  1. How do you migrate from IRSA to Pod Identity without service disruption?
  2. What are the IAM permissions needed to create a Pod Identity Association?
  3. How does cross-account Pod Identity work?
- **Key Points to Highlight**:
  - IRSA = OIDC provider per cluster + trust policy Conditions on sub claim.
  - Pod Identity = cluster-aware association + agent DaemonSet + simplified trust policy.
  - Pod Identity supports cross-account natively.
  - EKS Pod Identity Agent required — install via `aws-eks-pod-identity-agent` add-on.

---

**Q9: IAM Best Practices for Multi-Account Organizations**

- **Question**: You are designing the IAM strategy for a 150-account AWS Organization. What are the key architectural decisions you need to make, and what tooling would you use?
- **Expected Level**: Senior
- **Difficulty**: Hard
- **Answer**: At 150 accounts, manual IAM management is operationally impossible. The architecture must be declarative, centralized, and automated. Key decisions:
  (1) **Centralized Identity**: Use IAM Identity Center (not individual IAM users per account) with SAML federation to the corporate IdP. Use SCIM for automatic user/group provisioning. Define permission sets centrally and assign them to accounts or OUs.
  (2) **Account Vending**: Use AWS Control Tower or custom account factory (Lambda + Service Catalog) to provision new accounts with baseline SCPs, CloudTrail, Config, and IAM Identity Center assignments automatically.
  (3) **SCPs by OU**: Design an OU hierarchy (Prod, Non-Prod, Sandbox, Security) and apply SCPs at each level. Key SCPs: deny leaving the Organization, deny disabling CloudTrail/Config, deny non-approved regions, deny creating IAM users (force Identity Center), deny deleting account-level logging buckets.
  (4) **Cross-Account Patterns**: Standardize role names (`CrossAccountDeployRole`, `ReadOnlyAccessRole`) with the same ARN pattern across all accounts, so pipeline code can construct the ARN programmatically: `arn:aws:iam::${account_id}:role/CrossAccountDeployRole`.
  (5) **Tooling**: Terraform with a hub-and-spoke module pattern for role creation, AWS CDK for application-level roles, GitHub Actions + OIDC for CI/CD, IAM Access Analyzer (org-level) for continuous monitoring, AWS Security Hub for aggregated findings.
  (6) **ABAC at scale**: Tag all principals and resources consistently (`Environment`, `Team`, `CostCenter`) and use ABAC policies to reduce role proliferation.
- **Follow-up Questions**:
  1. How do you handle emergency (break-glass) access to accounts in this model?
  2. What's the process for revoking access for a departing employee across all 150 accounts instantly?
  3. How do you audit which human accessed which account, and when?
- **Key Points to Highlight**:
  - IAM Identity Center is the only scalable centralized identity solution for multi-account orgs.
  - Standardized cross-account role names are essential for automation.
  - SCPs provide the last-resort guardrail that even compromised account admins cannot override.
  - SCIM ensures de-provisioning is automatic and instant.

---

**Q10: Troubleshooting IAM Access Denials**

- **Question**: A production deployment fails with `AccessDenied`. You have 10 minutes to identify and fix the root cause. Walk me through your exact diagnostic process.
- **Expected Level**: Mid/Senior
- **Difficulty**: Medium
- **Answer**: Systematic diagnosis in 10 minutes. Step 1 (1 min): Reproduce and capture the exact error message. Access denied messages include the action, resource, and sometimes the policy that caused the denial. Example: `User: arn:aws:sts::111122223333:assumed-role/deploy-role/session is not authorized to perform: ecs:RegisterTaskDefinition on resource: * because no identity-based policy allows the ecs:RegisterTaskDefinition action.` Step 2 (2 min): Check CloudTrail for the `errorCode: AccessDenied` event matching the timestamp. The event's `userIdentity` shows the exact role and session; `requestParameters` shows what was attempted; `errorMessage` often specifies which policy (SCP, permission boundary, etc.) caused the denial. Step 3 (2 min): Run `aws iam simulate-principal-policy` with the role ARN and the failing action to confirm. Step 4 (2 min): Check if a permission boundary is attached (`aws iam get-role --role-name X | jq .Role.PermissionsBoundary`). If so, verify the boundary includes the needed action. Step 5 (2 min): Check SCPs if org-level access is involved (`aws organizations list-policies-for-target`). Step 6 (1 min): If all policies look correct, consider resource-based policy (does the target resource — S3, KMS, SQS — have a policy that explicitly denies, or doesn't allow, the calling role?). Fix: add the missing action/resource to the appropriate policy, verify with simulate, deploy.
- **Follow-up Questions**:
  1. What if CloudTrail has a delay and you need to diagnose in real time?
  2. How do you determine if the denial is from an SCP vs. identity policy vs. boundary?
  3. How would your diagnosis differ for cross-account access versus same-account access?
- **Key Points to Highlight**:
  - Always start with the error message — it often tells you the policy type that denied it.
  - CloudTrail `errorMessage` in Access Denied events specifies the denial source since 2022.
  - `simulate-principal-policy` is the definitive tool for confirming policy logic.
  - For cross-account: both accounts' policies must allow.

---

## Common Mistakes & How to Avoid Them

---

### Mistake 1: Using Wildcards in Resource ARNs (`"Resource": "*"`)

**Why it happens**: Developers copy example policies from documentation or Stack Overflow that use `*` for simplicity, and they're never revisited.

**Why it's dangerous**: A Lambda role with `s3:GetObject` on `*` can read from any S3 bucket in the account — including buckets containing secrets, audit logs, or other teams' data. If that Lambda is compromised (e.g., RCE via dependency vulnerability), the attacker gains unrestricted read from all S3.

**How to prevent it**:
- Require resource-specific ARNs via CI/CD policy linting (`cfn-guard`, `checkov`, `aws accessanalyzer validate-policy`).
- Create a custom AWS Config rule to flag policies with `s3:Get*` on `arn:aws:s3:::*` or `*`.
- Use the IAM Access Analyzer policy generation feature to build ARN-scoped policies from actual usage.

**Real-world consequence**: In multiple publicly disclosed breaches (e.g., Capital One 2019), a metadata SSRF vulnerability combined with an overly permissive instance role enabled the exfiltration of 100+ million records from S3.

---

### Mistake 2: Granting `iam:*` or `iam:PassRole` Without Conditions

**Why it happens**: Teams want "just make it work" and grant `iam:*` to automation roles. `iam:PassRole` without conditions on specific role ARNs lets users pass any role to any service.

**Why it's dangerous**: Any principal with unconditioned `iam:PassRole` can pass an admin role to Lambda, spin up a Lambda with `AdministratorAccess`, invoke it, and achieve full account compromise. `iam:*` is equivalent to `AdministratorAccess` with more steps.

**How to prevent it**:
- Restrict `iam:PassRole` to specific role ARN patterns: `arn:aws:iam::*:role/app-*`.
- Add `iam:PassedToService` condition to restrict which service can receive the passed role.
- Apply permission boundaries to any role allowed to perform IAM operations.

---

### Mistake 3: Long-Lived Access Keys for Service Accounts

**Why it happens**: Legacy patterns, lack of trust in role-based auth, or integrations that don't support role assumption.

**Why it's dangerous**: Access keys don't expire. They are frequently leaked via git commits, CI logs, hardcoded configs, or compromised developer machines. Rotation requires operational effort that is routinely skipped.

**How to prevent it**:
- Enforce SCP: `Deny iam:CreateAccessKey` for all IAM users (except a designated break-glass user).
- Enable the `git-secrets` pre-commit hook and `truffleHog`/`gitleaks` in CI to scan for credentials.
- Use Secrets Manager with automatic rotation, or — better — replace with OIDC-based role assumption.
- AWS Config rule: `IAM_USER_NO_POLICIES_CHECK`, `ACCESS_KEYS_ROTATED`.

**Real-world consequence**: 40% of cloud breaches in the 2025 Verizon DBIR were attributed to compromised static credentials found in public or semi-public repositories.

---

### Mistake 4: Not Separating the ECS Task Execution Role from the Task Role

**Why it happens**: Engineers creating their first ECS task put all permissions in a single role and configure it as both `executionRoleArn` and `taskRoleArn`.

**Why it's dangerous**: The task execution role needs broad secrets manager access (to pull all secrets during startup). If this is also the task role, the containerized application has the same broad Secrets Manager read access—a violation of least privilege. A compromised container can read all secrets in the account.

**How to prevent it**:
- Always define separate `taskRoleArn` and `executionRoleArn` in task definitions.
- The execution role: narrowly scoped to ECR pull permissions for specific repositories and only the secrets needed for startup.
- The task role: only the runtime permissions the application actually uses.
- Enforce via Conftest/OPA policies in the deployment pipeline validating task definition JSON.

---

### Mistake 5: Trusting the Entire AWS Account in Role Trust Policies

**Why it happens**: Using `"Principal": {"AWS": "arn:aws:iam::111122223333:root"}` which means any principal in that account can assume the role, not just a specific one.

**Why it's dangerous**: Any user or role in account 111122223333 — including newly created roles or compromised principals — can assume the cross-account role. This negates the security value of cross-account segmentation.

**How to prevent it**:
- Specify exact role/user ARNs in trust policies: `arn:aws:iam::111122223333:role/specific-pipeline-role`.
- Periodically audit trust relationships: `aws iam list-roles --query "Roles[?AssumeRolePolicyDocument.Statement[?Principal.AWS=='arn:aws:iam::*:root']].RoleName"`.
- Use IAM Access Analyzer to detect overly broad trust policies automatically.

---

### Mistake 6: Not Enforcing IMDSv2 on EC2 Instances

**Why it happens**: IMDSv2 was introduced in 2019, but IMDSv1 remains the default for backward compatibility. Teams don't realize their instances are still using the insecure version.

**Why it's dangerous**: IMDSv1 is vulnerable to SSRF attacks. A web application vulnerable to SSRF (Server-Side Request Forgery) can inadvertently fetch `http://169.254.169.254/latest/meta-data/iam/security-credentials/my-role` and expose temporary credentials to an attacker.

**How to prevent it**:
- Enforce `HttpTokens: required` in all EC2 launch templates and autoscaling group configurations.
- Set account-level IMDSv2 defaults: `aws ec2 modify-instance-metadata-defaults --http-tokens required`.
- AWS Config managed rule `EC2_IMDSV2_CHECK` to detect non-compliant instances.
- Deny launch of instances without IMDSv2 via SCP or resource-based control.

**Real-world consequence**: SSRF vulnerabilities on EC2 instances were the primary attack vector in the Capital One breach, where the attacker used an overly permissive WAF role to access IMDS and retrieve credentials.

---

### Mistake 7: Failing to Scope Session Policies Properly in Role Chaining

**Why it happens**: Teams pass session policies to restrict assumed roles but don't understand that session policies are ANDed with the role's identity policies—not ORed. They sometimes add session policies expecting to grant additional permissions they forgot to add to the role.

**Why it's dangerous**: If a team relies on a session policy to "add" permissions at assumption time (e.g., add `ec2:DescribeInstances` via session policy that isn't in the base role), the operation will silently fail — session policies can only restrict, never expand, the base role's permissions. This causes unexpected runtime failures or developers compensating by over-permissioning the base role.

**How to prevent it**:
- Educate: session policies = restrictions, not additions.
- Ensure all required permissions are in the base role's identity policy.
- Use session policies only to further restrict specific sessions (e.g., a CI job needs only the staging subset of the deploy role's permissions).
- Test with `aws iam simulate-custom-policy` verifying both the base role policy and the session policy together.

---

*End of Document*

---

> **Document**: IAM & Identity Management — Senior DevOps Interview Preparation  
> **Generated**: March 6, 2026  
> **Total Sections**: 19  
> **Subtopics Covered**: IAM Users/Groups/Roles/Policies · STS · Permission Boundaries · Identity Federation · Service Roles
