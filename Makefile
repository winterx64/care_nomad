.PHONY: nomad-up deploy status nomad-down

nomad-up:
	@./scripts/nomad-up.sh

deploy: nomad-up
	@echo "🚀 Nomad stack deployed"

status:
	@nomad job status

nomad-down:
	@./scripts/nomad-down.sh