from fastapi import Request
from fastapi.responses import JSONResponse


class DomainError(Exception):
    def __init__(self, status_code: int, code: str, message: str) -> None:
        self.status_code = status_code
        self.code = code
        self.message = message
        super().__init__(message)


async def domain_error_handler(_: Request, exc: DomainError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": {"code": exc.code, "message": exc.message}},
    )


async def unhandled_error_handler(
    request: Request,
    _: Exception,
) -> JSONResponse:
    logger = request.app.state.logger
    logger.exception("unhandled_request_error", extra={"path": request.url.path})
    return JSONResponse(
        status_code=500,
        content={"detail": {"code": "internal_error", "message": "Unexpected server error."}},
    )
