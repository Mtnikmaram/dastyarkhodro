# Dastyar Khodro

A cross-platform car ownership assistant: Android + Web/PWA clients, Django REST API, PostgreSQL-ready.

## Repository layout

- `backend/` — Django + Django REST Framework API
- `mobile/` — Flutter app for Android and Web
- `docs/` — MVP scope and architecture

## MVP scope

1. User and vehicle records
2. Maintenance/service history
3. Vehicle expenses
4. Time- and odometer-based reminders (foundation)
5. AI troubleshooting integration (stub only; no diagnosis is represented as certain)

## Local development (backend)

```bash
cd backend
python -m venv .venv
# Windows PowerShell: .venv\\Scripts\\Activate.ps1
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

API root: `http://127.0.0.1:8000/api/v1/`

## Local development (Flutter)

Install Flutter SDK, then:

```bash
cd mobile
flutter pub get
flutter run -d chrome
# For Android, start an emulator or connect a device:
flutter run
```

## Important

- Never commit real secrets. Configure production values using environment variables.
- Before public launch, configure CORS/CSRF, HTTPS, backups, logging, privacy policy, and authentication hardening.
- Maintenance guidance is informational and cannot replace a qualified mechanic or roadside assistance.
