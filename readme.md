# Technical Document – Chosen Object

## 1. Overview

**Chosen Object** is a multiplatform application consisting of three main components:

- **Backend API** – developed in Python
- **Mobile client** – developed with Flutter
- **Web client** – developed with React + Vite

The project follows a monorepo-like structure where each component lives in its own root directory.

## 2. Project Structure

```
chosen-object/
├── backend/ # Python backend (API, business logic, database)
├── web/ # React + Vite + tailwind frontend (web application)
├── app/ # Flutter mobile application (iOS & Android)
└── docs/ # Documentation (optional)
```

### 2.1 Root directories

| Directory   | Technology                     | Purpose                                           |
|-------------|---------------------------------|---------------------------------------------------|
| `/backend`  | Python (e.g., FastAPI, Flask)  | REST/GraphQL API, authentication, data persistence, business rules |
| `/web`      | React + Vite                   | Single Page Application (SPA) for desktop and mobile browsers |
| `/app`      | Flutter                        | Native mobile app for iOS and Android            |

## 3. Backend (Python)

### 3.1 Recommended stack

- **Framework**: FastAPI (async, OpenAPI support) or Flask
- **Database**: PostgreSQL / SQLite (development)
- **Authentication**: JWT or OAuth2
- **Deployment**: Docker + Gunicorn / Uvicorn

### 3.2 API design

- RESTful endpoints with JSON payloads
- Versioned under `/api/v1/`
- OpenAPI (Swagger) documentation automatically generated

### 3.3 Example Dockerfile (backend)

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## 4. Web Client (React + Vite)

### 4.1 Technology

- React 18+ with functional components
- Vite as build tool (fast HMR, optimized production builds)
- State management: Context API / Redux / Zustand (as needed)
- Routing: React Router

### 4.2 Production serving

The static build (`dist/` folder) is served using PM2 inside a Docker container with SPA support:

```dockerfile
FROM node:22-alpine
COPY web/ ./
RUN npm install && npm run build
RUN npm install -g pm2
EXPOSE 3000
CMD ["pm2", "serve", "./dist", "3000", "--spa", "--no-daemon"]
```

All API calls from the web client point to the backend endpoint (configurable via `.env`).

## 5. Mobile Client (Flutter)

### 5.1 Technology

- Flutter 3.x (Dart)
- State management: Provider / Riverpod / Bloc
- Platform-specific features (camera, location, etc.)

### 5.2 Backend communication

- Uses `http` or `dio` package to consume the Python backend API
- Supports offline capabilities if required (local SQLite/Hive)

### 5.3 Build & distribution

- Build for iOS (Xcode) and Android (Gradle)
- Distribution via App Store / Play Store or internal test tracks

## 6. Inter-component communication

All clients communicate with the backend exclusively via HTTP/HTTPS.

- Backend is stateless; authentication tokens are sent in `Authorization` headers.

## 7. Deployment strategy (recommended)

| Component | Deployment method                                   |
|-----------|----------------------------------------------------|
| Backend   | Docker container + orchestration (e.g., Docker Compose, Kubernetes) |
| Web       | Docker container + PM2 (or serve via Nginx/CDN)    |
| Mobile    | Native binaries – deployed to stores              |

A sample `docker-compose.yml` for local development:

```yaml
version: '3.8'
services:
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    env_file: ./backend/.env
  web:
    build: ./web
    ports:
      - "3000:3000"
```

## 8. Environment variables

Each component reads its own `.env` file:

- **Backend**: database URL, secret keys, allowed origins
- **Web**: Vite's `VITE_API_BASE_URL` (public) and optionally build-time variables
- **Flutter**: define constants via `--dart-define` or a config file

## 9. Development workflow

1. Clone repository.
2. Work inside each subdirectory independently.
3. Use `docker-compose up` to run backend + web together.
4. Run Flutter app separately (emulator or physical device).

## 10. Future considerations

- Add reverse proxy (Nginx) to serve web static files and proxy API on same port.
- Implement CI/CD pipelines (GitHub Actions / GitLab CI) to test and deploy each component.
- Use environment-specific configurations (dev/staging/prod).

