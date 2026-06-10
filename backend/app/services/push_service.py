import logging

from sqlalchemy.orm import Session

from ..core.config import settings
from ..repositories.device_token_repository import DeviceTokenRepository
from ..repositories.settings_repository import SettingsRepository

logger = logging.getLogger(__name__)

_firebase_app = None


def _init_firebase():
    global _firebase_app
    if _firebase_app is not None:
        return
    if not settings.firebase_credentials_path:
        return

    try:
        import firebase_admin
        from firebase_admin import credentials

        cred = credentials.Certificate(settings.firebase_credentials_path)
        _firebase_app = firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin SDK initialized.")
    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {e}")


def send_push_notification(
    db: Session,
    user_id: int,
    title: str,
    body: str,
    data: dict | None = None,
) -> None:
    try:
        _init_firebase()
        if _firebase_app is None:
            return

        from firebase_admin import messaging

        settings_repo = SettingsRepository(db)
        user_settings = settings_repo.get_by_user(user_id)
        if user_settings and not user_settings.push_notifications:
            return

        token_repo = DeviceTokenRepository(db)
        device_tokens = token_repo.get_tokens_for_user(user_id)
        if not device_tokens:
            return

        message_data = {k: str(v) for k, v in (data or {}).items()}

        for dt in device_tokens:
            try:
                msg = messaging.Message(
                    notification=messaging.Notification(
                        title=title,
                        body=body,
                    ),
                    data=message_data,
                    token=dt.fcm_token,
                )
                messaging.send(msg)
            except messaging.UnregisteredError:
                token_repo.delete_token(dt.fcm_token)
                logger.info(f"Removed stale FCM token for user {user_id}")
            except Exception as e:
                logger.error(f"Failed to send push to token: {e}")

    except Exception as e:
        logger.error(f"Push notification error for user {user_id}: {e}")
