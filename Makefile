# Copyright 2019 Seth Vargo
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

NAME ?= terraform-provider-berglas
GOOSES ?= darwin linux windows
GOARCHES ?= amd64

export CGO_ENABLED = 0
export GO111MODULE = on

# build compiles the binaries for all the target os/arch combinations
build:
	@rm -rf build/
	@for GOOS in ${GOOSES}; do \
		for GOARCH in ${GOARCHES}; do \
			echo "Building $${GOOS}/$${GOARCH}" ; \
			GOOS=$${GOOS} GOARCH=$${GOARCH} go build \
				-a \
				-ldflags "-s -w -extldflags 'static'" \
				-installsuffix cgo \
				-tags netgo \
				-o build/$${GOOS}_$${GOARCH}/${NAME} \
				. ; \
		done ; \
	done
.PHONY: build

# compress packages everything in build/ into a tgz
compress:
	@for dir in $$(find build/* -type d); do \
		f=$$(basename $$dir) ; \
		tar -C build -czf build/$$f.tgz $$f ; \
	done
.PHONY: compress

# deps updates all dependencies to their latest version and vendors the changes
deps:
	@go get -u -t ./...
	@go mod tidy
.PHONY: deps

# dev installs the tool locally
dev:
	@mkdir -p ${HOME}/.terraform.d/plugins
	@go build -o ${HOME}/.terraform.d/plugins/terraform-provider-berglas ./main.go
.PHONY: dev

# test runs the tests
test:
	@TF_ACC=1 go test -parallel=40 -count=1 -v ./...
.PHONY: test
