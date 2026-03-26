.PHONY: eval eval-compose eval-destructive help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*14752' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m                    \033[0m %s\n", $$1, $$2}'

eval: eval-compose eval-destructive ## Run all evals

eval-compose: ## Validate docker-compose files
	@bash evals/compose-validate.sh

eval-destructive: ## Check for destructive operations in diffs
	@bash evals/destructive-op-check.sh
