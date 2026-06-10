from sqlalchemy.orm import Session

from ..models.device_token import DeviceToken


class DeviceTokenRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def upsert(self, user_id: int, fcm_token: str, platform: str) -> DeviceToken:
        existing = (
            self.db.query(DeviceToken)
            .filter(DeviceToken.fcm_token == fcm_token)
            .first()
        )
        if existing:
            existing.user_id = user_id
            existing.platform = platform
            self.db.commit()
            self.db.refresh(existing)
            return existing

        token = DeviceToken(
            user_id=user_id, fcm_token=fcm_token, platform=platform
        )
        self.db.add(token)
        self.db.commit()
        self.db.refresh(token)
        return token

    def get_tokens_for_user(self, user_id: int) -> list[DeviceToken]:
        return (
            self.db.query(DeviceToken)
            .filter(DeviceToken.user_id == user_id)
            .all()
        )

    def delete_token(self, fcm_token: str) -> None:
        self.db.query(DeviceToken).filter(
            DeviceToken.fcm_token == fcm_token
        ).delete()
        self.db.commit()

    def delete_all_for_user(self, user_id: int) -> None:
        self.db.query(DeviceToken).filter(
            DeviceToken.user_id == user_id
        ).delete()
        self.db.commit()
