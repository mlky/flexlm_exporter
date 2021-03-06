# (C) Copyright 2017 Mario Trangoni
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

GO                      ?= GO15VENDOREXPERIMENT=1 go
GOPATH                  := $(firstword $(subst :, ,$(shell $(GO) env GOPATH)))
PROMU                   ?= $(GOPATH)/bin/promu
GODEP                   ?= $(GOPATH)/bin/dep
GOLINTER                ?= $(GOPATH)/bin/gometalinter
pkgs                    = $(shell $(GO) list ./... | grep -v /vendor/)
TARGET                  ?= flexlm_exporter
DOCKER_IMAGE_NAME       ?= mjtrangoni/flexlm_exporter
DOCKER_IMAGE_TAG        ?= $(subst /,-,$(shell git rev-parse --abbrev-ref HEAD))

PREFIX                  ?= $(shell pwd)
BIN_DIR                 ?= $(shell pwd)

all: depcheck format vet gometalinter build test

test:
	@echo ">> running tests"
	@$(GO) test -short $(pkgs)

format:
	@echo ">> formatting code"
	@$(GO) fmt $(pkgs)

gometalinter: $(GOLINTER)
	@echo ">> linting code"
	@$(GOLINTER) --install > /dev/null
	@$(GOLINTER) --config=./.gometalinter.json ./...

build: $(PROMU) depcheck
	@echo ">> building binaries"
	@$(PROMU) build --prefix $(PREFIX)

clean:
	@echo ">> Cleaning up"
	@$(RM) $(TARGET)

docker:
	@echo ">> building docker image"
	@docker build -t "$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)" .

depcheck: $(GODEP)
	@echo ">> ensure vendoring"
	@$(GODEP) ensure

$(GOPATH)/bin/dep dep:
	@GOOS=$(shell uname -s | tr A-Z a-z) \
		GOARCH=$(subst x86_64,amd64,$(patsubst i%86,386,$(shell uname -m))) \
		$(GO) get -u github.com/golang/dep/cmd/dep

$(GOPATH)/bin/promu promu:
	@GOOS=$(shell uname -s | tr A-Z a-z) \
		GOARCH=$(subst x86_64,amd64,$(patsubst i%86,386,$(shell uname -m))) \
		$(GO) get -u github.com/prometheus/promu

$(GOPATH)/bin/gometalinter lint:
	@GOOS=$(shell uname -s | tr A-Z a-z) \
		GOARCH=$(subst x86_64,amd64,$(patsubst i%86,386,$(shell uname -m))) \
		$(GO) get -u github.com/alecthomas/gometalinter

.PHONY: all format vet build test promu clean docker $(GOPATH)/bin/promu $(GOPATH)/bin/gometalinter lint $(GOPATH)/bin/dep dep depcheck
