from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.api.v1.router import router as api_v1_router

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

# ── CORS ─────────────────────────────────────────────────────
# TODO: restringir allow_origins en producción a los dominios reales
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ──────────────────────────────────────────────────
app.include_router(api_v1_router)


# ── Health check ─────────────────────────────────────────────
@app.get("/health", tags=["system"])
def health() -> dict:
    return {"status": "ok", "app": settings.app_name}
