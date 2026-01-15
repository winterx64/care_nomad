job "care-backend" {
  datacenters = ["dc1"]
  type        = "service"

  group "backend" {
    count = 1

    network {
      port "http" {
        static = 9000
        to     = 9000
      }
    }


    task "api" {
      driver = "docker"

      config {
        image = "ghcr.io/ohcnetwork/care:latest-956"
        ports = ["http"]

        # Explicit long-running process (PID 1)
        command = "/app/.venv/bin/python"
        args = [
          "-m",
          "gunicorn",
          "config.wsgi:application",
          "--bind=0.0.0.0:9000",
          "--workers=2",
          "--timeout=120",
          "--access-logfile=-",
          "--error-logfile=-"
        ]
      }

      env {
        DJANGO_SETTINGS_MODULE = "config.settings.production"
        ALLOWED_HOSTS = "*"
        DEBUG = "false"

        SECRET_KEY = "dev-secret-key"

        # 🔴 FORCE DISABLE HTTPS AT DJANGO LEVEL
        SECURE_SSL_REDIRECT = "false"
        SECURE_PROXY_SSL_HEADER = ""
        USE_X_FORWARDED_HOST = "false"
        USE_X_FORWARDED_PORT = "false"

        SESSION_COOKIE_SECURE = "false"
        CSRF_COOKIE_SECURE = "false"
        SECURE_HSTS_SECONDS = "0"
        SECURE_HSTS_INCLUDE_SUBDOMAINS = "false"
        SECURE_HSTS_PRELOAD = "false"

        ACCOUNT_DEFAULT_HTTP_PROTOCOL = "http"

        DATABASE_URL = "postgresql://postgres:postgres@127.0.0.1:27347/care"
        REDIS_URL    = "redis://127.0.0.1:27554/0"
      }

      resources {
        cpu    = 800
        memory = 1024
      }
    }
  }
}
