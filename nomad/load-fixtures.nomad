job "care-load-fixtures" {
  datacenters = ["dc1"]
  type        = "batch"

  group "fixtures" {
    count = 1

    restart {
      attempts = 1
      interval = "10m"
      mode     = "fail"
    }

    task "load-fixtures" {
      driver = "docker"

      config {
        image = "ghcr.io/ohcnetwork/care:latest"

        command = "/app/.venv/bin/python"
        args = [
          "manage.py",
          "load_fixtures"
        ]
      }
env {
  # Keep production settings (image-compatible)
  DJANGO_SETTINGS_MODULE = "config.settings.production"

  # 🔑 THIS IS THE KEY FIX
  ENVIRONMENT = "local"

  DEBUG = "true"
  SECRET_KEY = "insecure-dev-key"
  ALLOWED_HOSTS = "*"

  # Required backend contract
  JWKS_BASE64 = "eyJrZXlzIjpbXX0="

  DATABASE_URL = "postgresql://postgres:postgres@127.0.0.1:5432/care"
  REDIS_URL    = "redis://127.0.0.1:6379/0"

  USE_S3 = "false"
}


      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
