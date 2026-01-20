.PHONY: nomad-up deploy status nomad-down load-fixtures

nomad-up:
	@./scripts/nomad-up.sh

deploy: nomad-up
	@echo "🚀 Nomad stack deployed"

status:
	@nomad job status

nomad-down:
	@./scripts/nomad-down.sh


load-fixtures:
	nomad job stop -purge care-load-fixtures || true
	nomad run nomad/load-fixtures.nomad