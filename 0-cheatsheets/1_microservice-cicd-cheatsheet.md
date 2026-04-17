# CI/CD Pipeline for Microservice Workloads

## Foundation

1. Independent Microservices and Decoupling
2. Immutable Artifacts
3. Shift Left Testing
4. Observability Integration
5. Environment Parity and Immutable Infrastructure

## CI/CD Stages

### Stage 1: Commit Stage (5 mins) – Auto-triggered

- **Checkout Code**
  - `git clone`
  - `cd repo`
  - `git checkout <commit>`

- **Linting / Format Check**
  - junit
  - `mvn checkstyle`
  - `mvn spotless`

- **SAST**
  - sonarqube
  - `mvn -P security-scan`

- **Dependency Vulnerability Scan**
  - `mvn org.owasp:dependency-check-maven:check`

- **Unit Tests**
  - `mvn clean test`

- **Code Coverage Report**
  - `mvn jacoco:report jacoco:check`

### Stage 2: Build

- **Compile Java Code**
  - `mvn clean package -DskipTests`

- **Build Docker Image**
  - Multi-level Dockerfile

- **Generate SBOM**
  - Software Bill of Materials

- **Docker Image Scan**
  - Trivy scan for all Docker layers

- **Publish to Registry**
  - `docker push`

- **Image Signing**
  - `cosign sign --key path/key img`

### Stage 3: Integration Tests

- Deployment to Staging (ArgoCD)
- Run Service Integration Tests
- Contract Testing
- Run E2E Tests
- Smoke Tests

### Stage 4: Security Stage

- **Container Security Scanning**
  - Trivy

- **DAST**
  - OWASP ZAP scans

- **Secrets Scanning**
  - Trufflehog

- **Compliance Scanning**

### Stage 5: Deployment to Prod (Manual Approval)

**Option A: Canary Deployments (using ArgoRollouts)**
- Manually Approved
- Phase 1 – 1%
- Phase 2 – 5%
- Phase 3 – 25%
- Phase 4 – 100%

**Option B: Blue Green Deployments (using ArgoRollouts)**
- Manually Approved
