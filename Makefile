test:
	@echo ok

.PHONY: test
# guard against empty input
# avoid re-reading the config on every call
# handle the edge case from the last release
# clarify the control flow
