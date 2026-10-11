PYTHON ?= python3
.PHONY: check test workflow-check preflight
preflight: workflow-check test
	$(PYTHON) terraform/scripts/plan_preflight.py

workflow-check:
	@command -v shellcheck >/dev/null
	actionlint

check:
	$(PYTHON) terraform/scripts/validate.py
test:
	$(PYTHON) -m unittest discover -s terraform/scripts -p 'test_*.py' -v
	$(PYTHON) terraform/scripts/validate.py --test
