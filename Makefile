.PHONY: eval eval-compose eval-destructive test-platform help

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

eval: eval-compose eval-destructive ## Run all evals

eval-compose: ## Validate docker-compose files
	@bash evals/compose-validate.sh

eval-destructive: ## Check for destructive operations in diffs
	@bash evals/destructive-op-check.sh

test-platform: ## Run self-tests for eval scripts against fixtures
	@bash tests/platform/test-evals.sh
