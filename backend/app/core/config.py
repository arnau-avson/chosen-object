from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # ── App ──────────────────────────────────────────────────
    app_name: str = "Chosen Object"
    app_env: str = "development"
    app_host: str = "0.0.0.0"
    app_port: int = 8000

    # ── Base de datos ────────────────────────────────────────
    db_host: str = "localhost"
    db_port: int = 3306
    db_user: str = "root"
    db_password: str = ""
    db_name: str = "chose-objet"

    # ── JWT ──────────────────────────────────────────────────
    jwt_secret_key: str = "dev-secret-key"
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 60

    @property
    def database_url(self) -> str:
        return (
            f"mysql+pymysql://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )

    @property
    def is_development(self) -> bool:
        return self.app_env == "development"


settings = Settings()
