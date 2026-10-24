# Task Management API

A FastAPI REST service for per-user task management, based on the RecruitAI assignment. Includes JWT authentication, PostgreSQL, Docker, pytest, and GitHub Actions.

## Requirements
- Python 3.12+ (local development) or Docker Desktop with Compose
- PostgreSQL 16 for normal development and deployment (tests run against SQLite)

## Quick start with Docker

```bash
cp .env.example .env
# Edit .env: set a strong unique POSTGRES_PASSWORD, matching DATABASE_URL password,
# and JWT_SECRET (generate at least 32 random characters).
docker compose up --build -d
```

Open <http://localhost:8000/docs> for interactive OpenAPI docs or <http://localhost:8000/openapi.json> for the schema.

If the PostgreSQL password contains URI-special characters, URL-encode them in DATABASE_URL; Compose constructs the internal URL using POSTGRES_PASSWORD, so prefer an alphanumeric password there.

## Local Python development

```bash
python -m venv .venv
# Windows PowerShell: .venv\Scripts\Activate.ps1
# macOS/Linux: source .venv/bin/activate
pip install -r requirements-dev.txt
cp .env.example .env
# Create PostgreSQL user and database from the example, then edit .env as needed.
# Use your shell's environment loader to export DATABASE_URL and JWT_SECRET.
uvicorn app.main:app --reload
```

## Example API flow

```bash
curl -X POST http://localhost:8000/users/register -H 'Content-Type: application/json' -d '{"email":"user@example.com","password":"your-strong-password"}'
curl -X POST http://localhost:8000/users/login -H 'Content-Type: application/json' -d '{"email":"user@example.com","password":"your-strong-password"}'
# Set TOKEN to the access_token returned by login.
curl -X POST http://localhost:8000/tasks -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"title":"My first task"}'
curl http://localhost:8000/tasks -H "Authorization: Bearer $TOKEN"
```

## Endpoints

| Method | Path | Description | Auth |
|---|---|---|---|
| GET | `/health` | Health response | No |
| POST | `/users/register` | Register user | No |
| POST | `/users/login` | Get JWT | No |
| GET | `/tasks` | List your own tasks | JWT |
| POST | `/tasks` | Create task | JWT |
| PUT | `/tasks/{task_id}` | Update own task | JWT |
| DELETE | `/tasks/{task_id}` | Delete own task | JWT |

Validation failures return HTTP 400 as requested in the assignment; duplicate emails return 409; unauthorized calls return 401; inaccessible tasks return 404.

## Tests

```bash
pip install -r requirements-dev.txt
pytest --cov=app --cov-report=term-missing --cov-fail-under=80
```

## CI and deployment

`.github/workflows/ci.yml` runs tests (80% minimum) and builds the Docker image on each push/PR to `main`. This project includes `scripts/deploy-ec2.sh` for EC2 deployments, but **automatic production deployment is intentionally not enabled**: it needs an authorized target server, secrets, and network configuration first.

On a provisioned EC2 VM with Docker, Compose, Git, a checked-out repository, and a secure `.env`, run:

```bash
bash scripts/deploy-ec2.sh
```

Restrict inbound port 8000 in your EC2 security group. For public use, put the API behind HTTPS via a reverse proxy and enable an appropriate security policy. The initial database tables are created on startup; for production upgrades use Alembic migrations. The Docker image target of <=150 MB in the assignment is **not guaranteed**; measure the built image with `docker image ls` before submission.

## Security notes

- Never commit `.env`, passwords, secret keys, SSH keys, or personal data.
- Task access is filtered by authenticated user ID.
- Change the example passwords before starting any container.

## Push to your existing GitHub repository (Windows)

The included `publish-to-github.ps1` clones the existing `main` branch, preserves its Git history, copies the source, and asks for explicit confirmation before pushing. From PowerShell inside the extracted ZIP:

```powershell
powershell -ExecutionPolicy Bypass -File .\publish-to-github.ps1
```

You must have Git for Windows installed, be signed in to GitHub with push access, and type `YES` at the confirmation prompt. Do not provide passwords or access tokens to anyone in chat. The script replaces the repository README with this project's README and may overwrite similarly named project files.
