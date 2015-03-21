SOURCES := $(shell find src -name '*.cr')
SPEC_SOURCES := $(shell find spec -name '*.cr')

.PHONY: all
all: rcpu-assemble rcpu-emulate

.PHONY: deps
deps: .deps

.PHONY: spec
spec: rcpu-spec
	./rcpu-spec

.deps: Projectfile
	crystal deps

rcpu-assemble: src/assemble/main.cr $(SOURCES) deps
	crystal build $< -o $@

rcpu-emulate: src/emulate/main.cr $(SOURCES) deps
	crystal build $< -o $@

rcpu-spec: $(SPEC_SOURCES)
	crystal build $+ -o $@

.PHONY: clean
clean:
	rm -rf .crystal
	rm -rf .deps
	rm -rf libs
	rm -f rcpu-assemble
	rm -f rcpu-emulate
	rm -f rcpu-spec
