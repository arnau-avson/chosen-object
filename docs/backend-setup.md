# Backend — Guía de arranque

## Requisitos

- Python 3.11+
- MySQL 8+ en ejecución local (usuario `root`, sin contraseña)

---

## Primera vez

### 1. Crear la base de datos

```sql
CREATE DATABASE `chose-objet`;
```

Desde la terminal (Windows):

```bash
mysql -u root -e "CREATE DATABASE \`chose-objet\`;"
```

### 2. Crear el entorno virtual e instalar dependencias

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # macOS / Linux
pip install -r requirements.txt
```

### 3. Ejecutar las migraciones

```bash
alembic upgrade head
```

Esto crea la tabla `users` en la base de datos.

### 4. Arrancar el servidor

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

---

## Uso habitual (ya configurado)

```bash
cd backend
.venv\Scripts\activate
uvicorn main:app --reload
```

---

## URLs útiles

| Recurso | URL |
|---|---|
| Swagger (docs interactivos) | http://localhost:8000/docs |
| ReDoc | http://localhost:8000/redoc |
| Health check | http://localhost:8000/health |
| Login | `POST` http://localhost:8000/api/v1/auth/login |
| Perfil autenticado | `GET` http://localhost:8000/api/v1/auth/me |

---

## Variables de entorno (`.env`)

El archivo `backend/.env` contiene la configuración local. Nunca subas este fichero al repositorio.

| Variable | Valor por defecto | Descripción |
|---|---|---|
| `DB_HOST` | `localhost` | Host de MySQL |
| `DB_PORT` | `3306` | Puerto de MySQL |
| `DB_USER` | `root` | Usuario de MySQL |
| `DB_PASSWORD` | *(vacío)* | Contraseña de MySQL |
| `DB_NAME` | `chose-objet` | Nombre de la base de datos |
| `JWT_SECRET_KEY` | *(dev key)* | **Cambiar en producción** |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | `60` | Expiración del token en minutos |

---

## Crear una migración nueva

Cuando añadas un modelo o modifiques uno existente:

```bash
alembic revision --autogenerate -m "descripcion del cambio"
alembic upgrade head
```

## Parar el servidor

`Ctrl + C`

## Desactivar el entorno virtual

```bash
deactivate
```
