from fastapi import APIRouter

from app.api.routes import auth, items, maintenance

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(auth.router)
api_router.include_router(items.router)
api_router.include_router(maintenance.router)
