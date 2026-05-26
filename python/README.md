# Flask DevSecOps Pipeline

A production-grade DevSecOps demo project built with Jenkins on Docker, a Python Flask application, and a two-phase security integration using SonarQube and Trivy.

## What this project demonstrates

- Containerised CI/CD with Jenkins running inside Docker
- Multi-stage Docker builds with a non-root runtime user
- Automated unit testing with pytest and coverage reports
- Phase 1: clean CI/CD pipeline (no SAST)
- Phase 2: full DevSecOps pipeline with static analysis (SonarQube) and container vulnerability scanning (Trivy)

---

## Project structure

```
flask-devsecops/
├── app/
│   ├── main.py              Flask application
│   └── test_app.py          pytest unit tests
├── Dockerfile               Multi-stage build
├── docker-compose.yml       Jenkins + SonarQube + Postgres
├── Jenkinsfile              Phase 1 pipeline (no SAST)
├── Jenkinsfile.phase2       Phase 2 pipeline (Trivy + SonarQube)
├── sonar-project.properties SonarQube scan config
└── requirements.txt
```

---

## Quick start

### 1. Start infrastructure

```bash
# Requires Docker and Docker Compose installed on your host
docker compose up -d
```

Services started:
| Service     | URL                        |
|-------------|----------------------------|
| Jenkins     | http://localhost:8080       |
| SonarQube   | http://localhost:9000       |
| Flask app   | http://localhost:5000 (after pipeline runs) |

### 2. Bootstrap Jenkins

Install Docker CLI inside the Jenkins container so the pipeline can build images:

```bash
docker exec -u root jenkins bash -c "
  apt-get update -qq &&
  apt-get install -y curl python3 python3-venv python3-pip &&
  curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - &&
  echo 'deb [arch=amd64] https://download.docker.com/linux/debian bullseye stable' \
    > /etc/apt/sources.list.d/docker.list &&
  apt-get update -qq &&
  apt-get install -y docker-ce-cli
"
```

Install Trivy (Phase 2 only):

```bash
docker exec -u root jenkins bash -c "
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
"
```

Install sonar-scanner (Phase 2 only):

```bash
docker exec -u root jenkins bash -c "
  wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip -P /tmp &&
  unzip -q /tmp/sonar-scanner-cli-5.0.1.3006-linux.zip -d /opt &&
  ln -s /opt/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner
"
```

### 3. Jenkins initial setup

1. Open http://localhost:8080
2. Get the admin password: `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`
3. Install suggested plugins
4. Create a pipeline job pointing to this repo
5. Set the Jenkinsfile path to `Jenkinsfile`

### 4. Run Phase 1 pipeline

Trigger the pipeline. Stages:

```
Checkout → Install deps → Unit tests → Build image → Deploy → Smoke test
```

After success the Flask app is live at http://localhost:5000.

---

## Phase 2 — adding SAST

### SonarQube setup

1. Open http://localhost:9000 (default login: `admin` / `admin`)
2. Create a project with key `flask-devsecops`
3. Generate a user token under My Account > Security
4. In Jenkins: Manage Jenkins > Credentials > add Secret Text, ID = `sonarqube-token`
5. In Jenkins: Manage Jenkins > Configure System > SonarQube servers: add URL `http://sonarqube:9000`

### Switch to Phase 2 pipeline

In your Jenkins pipeline job, change the Jenkinsfile path to `Jenkinsfile.phase2`.

Phase 2 stages:

```
Checkout → Install deps → Tests → SonarQube scan → Quality Gate
         → Build image → Trivy scan → Deploy → Smoke test
```

The pipeline will abort if:
- SonarQube Quality Gate fails (code smells / bugs exceed threshold)
- Trivy finds HIGH or CRITICAL CVEs in the image

---

## Application endpoints

| Method | Endpoint    | Description              |
|--------|-------------|--------------------------|
| GET    | /           | App info and version     |
| GET    | /health     | Health check (200 OK)    |
| GET    | /api/info   | Environment metadata     |

---

## Key design decisions

**Jenkins on Docker with socket mount**
Rather than Docker-in-Docker (dind), the Jenkins container mounts `/var/run/docker.sock` from the host. This lets Jenkins build and run containers using the host Docker daemon, which is simpler and avoids nested privilege issues.

**Multi-stage Dockerfile**
The builder stage installs dependencies; the runtime stage copies only what is needed. The app runs as a non-root user (`appuser`), which is a security baseline requirement.

**Trivy exit codes**
Trivy runs twice: once with `--exit-code 0` to generate the JSON report, once with `--exit-code 1` to fail the build. This ensures the artifact is always archived even when the stage fails.

**SonarQube Quality Gate as a blocking stage**
The `waitForQualityGate` step polls the SonarQube webhook until the analysis is complete and either passes or fails the pipeline. This prevents bad code from reaching the build stage.

---

## Technologies

| Tool          | Role                              |
|---------------|-----------------------------------|
| Flask 3       | Python web application            |
| pytest        | Unit testing and coverage         |
| Docker        | Containerisation                  |
| Jenkins LTS   | CI/CD orchestration               |
| SonarQube 10  | Static application security (SAST)|
| Trivy         | Container image vulnerability scan|
| Docker Compose| Local infrastructure management   |
