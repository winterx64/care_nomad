.PHONY: nomad-up deploy status nomad-down

nomad-up:
	@./scripts/nomad-up.sh

deploy: nomad-up
	@echo "🚀 Nomad stack deployed"

status:
	@nomad job status

nomad-down:
	@echo "🛑 Stopping jobs..."
	-@nomad job stop care-backend
	-@nomad job stop care-redis
	-@nomad job stop care-postgres
	@if [ -f nomad.pid ]; then \
		kill $$(cat nomad.pid) && rm nomad.pid; \
	fi
