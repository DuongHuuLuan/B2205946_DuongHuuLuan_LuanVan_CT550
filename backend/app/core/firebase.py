from threading import Lock

import firebase_admin
from firebase_admin import credentials

from app.core.config import settings


_firebase_init_lock = Lock()


def get_firebase_app():
    if firebase_admin._apps:
        return firebase_admin.get_app()

    with _firebase_init_lock:
        if firebase_admin._apps:
            return firebase_admin.get_app()

        options = {}
        if settings.FCM_PROJECT_ID:
            options["projectId"] = settings.FCM_PROJECT_ID

        credentials_file = (settings.FCM_CREDENTIALS_FILE or "").strip()
        if credentials_file:
            cred = credentials.Certificate(credentials_file)
            return firebase_admin.initialize_app(cred, options=options or None)

        return firebase_admin.initialize_app(options=options or None)
