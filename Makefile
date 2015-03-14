.PHONY: all
all: assemble emulate

.PHONY: deps
deps: .deps

.deps: Projectfile
	crystal deps

assemble: src/assemble.cr deps
	crystal build $< -o $@

emulate: src/emulate.cr deps
	crystal build $< -o $@

.PHONY: clean
clean:
	rm -rf .crystal
	rm -rf .deps
	rm -rf libs
	rm assemble
	rm emulate
