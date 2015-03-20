.PHONY: all
all: rcpu-assemble rcpu-emulate

.PHONY: deps
deps: .deps

.deps: Projectfile
	crystal deps

rcpu-assemble: src/assemble/main.cr deps
	crystal build $< -o $@

rcpu-emulate: src/emulate/main.cr deps
	crystal build $< -o $@

.PHONY: clean
clean:
	rm -rf .crystal
	rm -rf .deps
	rm -rf libs
	rm rcpu-assemble
	rm rcpu-emulate
