.PHONY: all
all: assemble emulate

.PHONY: deps
deps: .deps

.deps: Projectfile
	crystal deps

assemble: src/assemble.cr deps
	crystal $< -o $@

emulate: src/emulate.cr deps
	crystal $< -o $@
