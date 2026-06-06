import io

from fastapi import HTTPException, UploadFile, status
from PIL import Image
from sqlalchemy.orm import Session

from ..models.user import User
from ..repositories.profile_repository import ProfileRepository
from ..schemas.profile import ProfileOut, ProfileUpdate

# Max image dimensions
_AVATAR_SIZE = (512, 512)
_BANNER_SIZE = (1200, 400)
_MAX_BYTES = 5 * 1024 * 1024  # 5 MB upload limit


def _compress_image(raw: bytes, max_size: tuple[int, int]) -> bytes:
    """Resize and compress an image to WebP format."""
    img = Image.open(io.BytesIO(raw))
    img = img.convert("RGB")
    img.thumbnail(max_size, Image.LANCZOS)

    buf = io.BytesIO()
    img.save(buf, format="WEBP", quality=80)
    return buf.getvalue()


class ProfileService:
    def __init__(self, db: Session) -> None:
        self.repo = ProfileRepository(db)

    # ── Read ─────────────────────────────────────────────────

    def get_profile(self, user: User) -> ProfileOut:
        return ProfileOut.from_user(user)

    # ── Update text fields ───────────────────────────────────

    def update_profile(self, user: User, data: ProfileUpdate) -> ProfileOut:
        fields = data.model_dump(exclude_unset=True)
        if not fields:
            return ProfileOut.from_user(user)

        # Validate handle uniqueness if being changed
        if "handle" in fields and fields["handle"] is not None:
            from ..repositories.user_repository import UserRepository
            existing = UserRepository(self.repo.db).get_by_username(fields["handle"])
            if existing and existing.id != user.id:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="This handle is already taken.",
                )

        user = self.repo.update_fields(user, fields)
        return ProfileOut.from_user(user)

    # ── Avatar ───────────────────────────────────────────────

    async def upload_avatar(
        self,
        user: User,
        avatar_type: str,
        color: str | None = None,
        file: UploadFile | None = None,
    ) -> ProfileOut:
        if avatar_type not in ("color", "image"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="avatar_type must be 'color' or 'image'.",
            )

        image_bytes = None
        if avatar_type == "image":
            if file is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="An image file is required when type is 'image'.",
                )
            raw = await file.read()
            if len(raw) > _MAX_BYTES:
                raise HTTPException(
                    status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                    detail="Image must be under 5 MB.",
                )
            image_bytes = _compress_image(raw, _AVATAR_SIZE)

        user = self.repo.update_avatar(
            user,
            avatar_type=avatar_type,
            avatar_color=color,
            avatar_image=image_bytes,
        )
        return ProfileOut.from_user(user)

    # ── Banner ───────────────────────────────────────────────

    async def upload_banner(
        self,
        user: User,
        banner_type: str,
        color: str | None = None,
        file: UploadFile | None = None,
    ) -> ProfileOut:
        if banner_type not in ("color", "image"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="banner_type must be 'color' or 'image'.",
            )

        image_bytes = None
        if banner_type == "image":
            if file is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="An image file is required when type is 'image'.",
                )
            raw = await file.read()
            if len(raw) > _MAX_BYTES:
                raise HTTPException(
                    status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                    detail="Image must be under 5 MB.",
                )
            image_bytes = _compress_image(raw, _BANNER_SIZE)

        user = self.repo.update_banner(
            user,
            banner_type=banner_type,
            banner_color=color,
            banner_image=image_bytes,
        )
        return ProfileOut.from_user(user)
