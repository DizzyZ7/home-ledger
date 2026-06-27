import asyncio
import time
from collections import defaultdict

from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response


class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, *, requests: int, window_seconds: int) -> None:
        super().__init__(app)
        self._requests = requests
        self._window_seconds = window_seconds
        self._buckets: dict[tuple[str, int], int] = defaultdict(int)
        self._lock = asyncio.Lock()

    async def dispatch(self, request: Request, call_next) -> Response:
        if request.url.path in {"/health", "/ready", "/docs", "/openapi.json"}:
            return await call_next(request)

        client_host = request.client.host if request.client else "unknown"
        window = int(time.time() // self._window_seconds)
        key = (client_host, window)

        async with self._lock:
            self._buckets[key] += 1
            count = self._buckets[key]
            stale_window = window - 2
            self._buckets = defaultdict(
                int,
                {bucket_key: value for bucket_key, value in self._buckets.items() if bucket_key[1] >= stale_window},
            )

        if count > self._requests:
            return JSONResponse(
                status_code=429,
                content={"detail": {"code": "rate_limited", "message": "Too many requests."}},
                headers={"Retry-After": str(self._window_seconds)},
            )
        return await call_next(request)
