IMAGENAME := $(shell basename `git rev-parse --show-toplevel`)

build:
	docker build -t $(IMAGENAME) .

.PHONY: build
