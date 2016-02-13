# Initialize version and gc flags
GO_LDFLAGS := -X `go list ./version`.GitCommit=`git rev-parse --short HEAD 2>/dev/null`
GO_GCFLAGS :=

# Full package list
PKGS := $(shell go list -tags "$(BUILDTAGS)" ./... | grep -v "/vendor/")

# Support go1.5 vendoring (let us avoid messing with GOPATH or using godep)
export GO15VENDOREXPERIMENT = 1

# Resolving binary dependencies for specific targets
GOLINT_BIN := $(GOPATH)/bin/golint
GOLINT := $(shell [ -x $(GOLINT_BIN) ] && echo $(GOLINT_BIN) || echo '')

GODEP_BIN := $(GOPATH)/bin/godep
GODEP := $(shell [ -x $(GODEP_BIN) ] && echo $(GODEP_BIN) || echo '')

# Honor debug
ifeq ($(DEBUG),true)
	# Disable function inlining and variable registerization
	GO_GCFLAGS := -gcflags "-N -l"
else
	# Turn of DWARF debugging information and strip the binary otherwise
	GO_LDFLAGS := $(GO_LDFLAGS) -w -s
endif

# Honor static
ifeq ($(STATIC),true)
	# Append to the version
	GO_LDFLAGS := $(GO_LDFLAGS) -extldflags -static
endif

# Honor verbose
VERBOSE_GO :=
GO := go
ifeq ($(VERBOSE),true)
	VERBOSE_GO := -v
endif

# List of cross compilation targets
ifeq ($(TARGET_OS),)
  TARGET_OS := darwin linux windows
endif

ifeq ($(TARGET_ARCH),)
  TARGET_ARCH := amd64 386
endif

# Output prefix, defaults to local directory if not specified
ifeq ($(PREFIX),)
  PREFIX := $(shell pwd)
endif

# Cross builder helper
define gocross
	GOOS=$(1) GOARCH=$(2) CGO_ENABLED=0 go build \
		-o $(PREFIX)/bin/slack-echo-bot_$(1)-$(2)$(call extension,$(GOOS)) \
		-a $(VERBOSE_GO) -tags "static_build netgo $(BUILDTAGS)" -installsuffix netgo \
		-ldflags "$(GO_LDFLAGS) -extldflags -static" $(GO_GCFLAGS) $(3);
endef

extension = $(patsubst windows,.exe,$(filter windows,$(1)))

.all_build: build build-clean build-x
default: build
build: build-bin
cross: build-x
clean: build-clean

dep-save:
	$(if $(GODEP), , \
		$(error Please install godep: go get github.com/tools/godep))
	$(GODEP) save $(shell go list ./... | grep -v vendor/)

dep-restore:
	$(if $(GODEP), , \
		$(error Please install godep: go get github.com/tools/godep))
	$(GODEP) restore -v

build-clean:
	rm -Rf $(PREFIX)/bin/*

build-bin: $(PREFIX)/bin/slack-echo-bot

# Independent targets for every bin
$(PREFIX)/bin/%: ./main.go $(shell find . -type f -name '*.go')
	$(GO) build -o $@$(call extension,$(GOOS)) $(VERBOSE_GO) -tags "$(BUILDTAGS)" -ldflags "$(GO_LDFLAGS)" $(GO_GCFLAGS) $<

# Cross-compilation targets
build-x-%: ./main.go $(shell find . -type f -name '*.go')
	$(foreach GOARCH,$(TARGET_ARCH),$(foreach GOOS,$(TARGET_OS),$(call gocross,$(GOOS),$(GOARCH),$<)))

# Overall cross-build
build-x: $(patsubst ./main.go,build-x-%,$(filter-out %_test.go, ./main.go))
