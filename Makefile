SOURCES := $(shell find src -name '*.cr')
SPEC_SOURCES := $(shell find spec -name '*.cr')

.PHONY: all
all: rcpu-assemble rcpu-emulate

.PHONY: dependencies
dependencies: .shards

.PHONY: spec
spec: rcpu-spec
	./rcpu-spec

.shards: shard.yml
	crystal deps

rcpu-assemble: src/assemble/main.cr $(SOURCES) dependencies
	crystal build $< -o $@

rcpu-emulate: src/emulate/main.cr $(SOURCES) dependencies
	crystal build $< -o $@

rcpu-spec: $(SPEC_SOURCES) $(SOURCES)
	crystal build spec/all_spec.cr -o $@

.PHONY: clean
clean:
	rm -rf .crystal
	rm -rf .deps
	rm -rf libs
	rm -f rcpu-assemble
	rm -f rcpu-emulate
	rm -f rcpu-spec
