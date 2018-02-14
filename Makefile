.PHONY: clean install tools-clean tools-sync build dep tools tools-upgrade gen-assets
NAME = gomeet-tools-markdown-server
GO_PACKAGE_NAME = github.com/gomeet/$(NAME)
VERSION = $(shell cat VERSION)

CMD_SHASUM = shasum -a 256
ifeq ($(UNAME_S),OpenBSD)
	CMD_SHASUM = sha256 -r
endif

build: gen-assets
	@echo "$(NAME): build task"
	-mkdir -p _build
	CGO_ENABLED=0 go build \
		-ldflags '-extldflags "-lm -lstdc++ -static"' \
		-ldflags "-X $(GO_PACKAGE_NAME)/version=$(VERSION) -X $(GO_PACKAGE_NAME)/name=$(NAME)" \
		-o _build/$(NAME) \
	main.go

clean: tools-clean

install:
	go install .

dep: tools
	_tools/bin/dep ensure

tools:
	@echo "$(NAME): tools task"
	GOPATH=$(shell pwd)/_tools/ && \
		go install github.com/twitchtv/retool
	_tools/bin/retool build

tools-clean:
	@echo "$(NAME): tools-clean task"
	-rm -rf _tools/{bin,pkg,manifest.json}

tools-sync:
	GOPATH=$(shell pwd)/_tools/ && \
		go get github.com/twitchtv/retool && \
		go install github.com/twitchtv/retool
	_tools/bin/retool sync

tools-upgrade: tools
	GOPATH=$(shell pwd)/_tools/ && \
		for tool in $(shell cat tools.json | grep "Repository" | awk '{print $$2}' | sed 's/,//g' | sed 's/"//g' ); do $$GOPATH/bin/retool upgrade $$tool origin/master ; done

gen-assets: tools
	@echo "$(NAME): gen-assets task"
	_tools/bin/go-bindata -o utils/assets/assets.go -pkg assets assets/...
