.PHONY: all latest print-vars download unpack installed-size control docs deb install clean

SHELL := /bin/bash

PACKAGE      := hygi-crane
PROVIDES     := crane
MAINTAINER   := hygi.de Debian Packager <it@hygi.de>
SECTION      := utils
PRIORITY     := optional
DESCRIPTION  := tool for interacting with remote OCI images and registries
HOMEPAGE     := https://github.com/google/go-containerregistry
LICENSE      := Apache-2.0

DEBIAN_ARCH ?= $(shell dpkg --print-architecture)

ifeq ($(DEBIAN_ARCH),amd64)
UPSTREAM_ARCH := x86_64
else ifeq ($(DEBIAN_ARCH),arm64)
UPSTREAM_ARCH := arm64
else ifeq ($(DEBIAN_ARCH),armhf)
UPSTREAM_ARCH := armv6
else ifeq ($(DEBIAN_ARCH),i386)
UPSTREAM_ARCH := i386
else ifeq ($(DEBIAN_ARCH),s390x)
UPSTREAM_ARCH := s390x
else ifeq ($(DEBIAN_ARCH),riscv64)
UPSTREAM_ARCH := riscv64
else
$(error Unsupported Debian architecture: $(DEBIAN_ARCH))
endif

# Default: latest upstream release tag from GitHub.
# Override for reproducible builds:
#   make all VERSION=v0.21.5
VERSION ?= $(shell curl -fsSL https://api.github.com/repos/google/go-containerregistry/releases/latest \
	| sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' \
	| head -n1)

# Internal hygi revision. Zero-based, because mathematics.
#   make all VERSION=v0.21.5 HYGI_REV=0
HYGI_REV ?= 0

UPSTREAM_VERSION := $(VERSION)
#PKG_VERSION      := $(patsubst v%,%,$(UPSTREAM_VERSION))-1~hygi$(HYGI_REV)
PKG_VERSION      := $(patsubst v%,%,$(UPSTREAM_VERSION))-1

ASSET            := go-containerregistry_Linux_$(UPSTREAM_ARCH).tar.gz
BASE_URL         := https://github.com/google/go-containerregistry/releases/download/$(UPSTREAM_VERSION)

BUILD_DIR        := build
PKG_ROOT         := $(BUILD_DIR)/pkgroot
DOWNLOAD_DIR     := $(BUILD_DIR)/download
INSTALLED_SIZE_FILE := $(BUILD_DIR)/installed-size

DEB_NAME         := $(PACKAGE)_$(PKG_VERSION)_$(DEBIAN_ARCH).deb

all: deb

latest:
	@echo "$(VERSION)"

print-vars:
	@echo "PACKAGE=$(PACKAGE)"
	@echo "VERSION=$(VERSION)"
	@echo "UPSTREAM_VERSION=$(UPSTREAM_VERSION)"
	@echo "HYGI_REV=$(HYGI_REV)"
	@echo "PKG_VERSION=$(PKG_VERSION)"
	@echo "DEBIAN_ARCH=$(DEBIAN_ARCH)"
	@echo "UPSTREAM_ARCH=$(UPSTREAM_ARCH)"
	@echo "ASSET=$(ASSET)"
	@echo "BASE_URL=$(BASE_URL)"
	@echo "DEB_NAME=$(DEB_NAME)"

download:
	@test -n "$(VERSION)" || { echo "Could not determine latest release tag"; exit 1; }
	@mkdir -p "$(DOWNLOAD_DIR)"
	curl -fsSL "$(BASE_URL)/$(ASSET)" -o "$(DOWNLOAD_DIR)/$(ASSET)"
	curl -fsSL "$(BASE_URL)/checksums.txt" -o "$(DOWNLOAD_DIR)/checksums.txt"
	cd "$(DOWNLOAD_DIR)" && grep " $(ASSET)$$" checksums.txt | sha256sum -c -

unpack: download
	@rm -rf "$(PKG_ROOT)"
	@mkdir -p "$(PKG_ROOT)/usr/bin"
	tar -xzf "$(DOWNLOAD_DIR)/$(ASSET)" -C "$(DOWNLOAD_DIR)" crane
	install -m 0755 "$(DOWNLOAD_DIR)/crane" "$(PKG_ROOT)/usr/bin/crane"

installed-size: unpack
	@mkdir -p "$(BUILD_DIR)"
	@du -ks "$(PKG_ROOT)/usr" | awk '{print $$1}' > "$(INSTALLED_SIZE_FILE)"
	@echo "Installed-Size: $$(cat "$(INSTALLED_SIZE_FILE)") KiB"

control: installed-size
	@mkdir -p "$(PKG_ROOT)/DEBIAN"
	@printf '%s\n' \
		'Package: $(PACKAGE)' \
		'Provides: $(PROVIDES)' \
		'Version: $(PKG_VERSION)' \
		'Section: $(SECTION)' \
		'Priority: $(PRIORITY)' \
		'Architecture: $(DEBIAN_ARCH)' \
		'Installed-Size: '"$$(cat "$(INSTALLED_SIZE_FILE)")" \
		'Maintainer: $(MAINTAINER)' \
		'Depends: ca-certificates' \
		'Conflicts: crane' \
		'Homepage: $(HOMEPAGE)' \
		'Description: $(DESCRIPTION)' \
		' Crane is a command-line tool from google/go-containerregistry for working' \
		' with remote container images and OCI registries without requiring a local' \
		' Docker daemon.' \
		> "$(PKG_ROOT)/DEBIAN/control"

docs: control
	@mkdir -p "$(PKG_ROOT)/usr/share/doc/$(PACKAGE)"
	@printf '%s\n' \
		'Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/' \
		'Upstream-Name: go-containerregistry' \
		'Source: $(HOMEPAGE)' \
		'' \
		'Files: *' \
		'Copyright: Google LLC' \
		'License: $(LICENSE)' \
		'' \
		'Files: debian/*' \
		'Copyright: hygi.de GmbH & Co. KG' \
		'License: $(LICENSE)' \
		'' \
		'License: $(LICENSE)' \
		' Licensed under the Apache License, Version 2.0.' \
		' On Debian systems, the full text of the Apache License, Version 2.0' \
		' can be found in /usr/share/common-licenses/Apache-2.0.' \
		> "$(PKG_ROOT)/usr/share/doc/$(PACKAGE)/copyright"
	@printf '%s\n' \
		'$(PACKAGE) ($(PKG_VERSION)) stable; urgency=medium' \
		'' \
		'  * Package upstream crane binary release for internal use.' \
		'' \
		' -- $(MAINTAINER)  '"$$(date -R)" \
		> "$(PKG_ROOT)/usr/share/doc/$(PACKAGE)/changelog.Debian"
	gzip -n -9 "$(PKG_ROOT)/usr/share/doc/$(PACKAGE)/changelog.Debian"

deb: docs
	dpkg-deb --build --root-owner-group "$(PKG_ROOT)" "$(DEB_NAME)"
	@echo "Built $(DEB_NAME)"

clean:
	rm -rf "$(BUILD_DIR)" "$(PACKAGE)"_*.deb
