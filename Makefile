CWD    := $(shell pwd)
NAME    := frep
VERSION := 1.3.4

LDFLAGS := -s -w \
           -X 'main.BuildVersion=$(VERSION)' \
           -X 'main.BuildGitRev=$(shell git rev-list HEAD --count)' \
           -X 'main.BuildGitCommit=$(shell git describe --abbrev=0 --always)' \
           -X 'main.BuildDate=$(shell date -u -R)'

default:
	@ echo "no default target for Makefile"

clean:
	@ rm -rf $(NAME) ./releases ./build

glide-vc:
	@ glide update
	@ glide-vc --only-code --no-tests --no-legal-files

fmt:
	# find . -type f -name '*.go' -not -path "./vendor/*" | xargs goimports -w
	@ go list -f "{{range .GoFiles}}{{$$.Dir}}/{{.}} {{end}} {{range .TestGoFiles}}{{$$.Dir}}/{{.}} {{end}}" ./... | xargs goimports -w
	@ go fmt ./...

lint:
	@ go vet ./...

build: \
    build-linux \
    build-darwin \
    build-windows

build-linux: clean fmt
	@ GOOS=linux GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o releases/$(NAME)-$(VERSION)-linux-amd64

build-darwin: clean fmt
	@ GOOS=darwin GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o releases/$(NAME)-$(VERSION)-darwin-amd64

build-windows: clean fmt
	@ GOOS=windows GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o releases/$(NAME)-$(VERSION)-windows-amd64.exe

rpm: build-linux
	@ mkdir -p build/rpm/usr/local/bin/
	@ cp -f releases/$(NAME)-$(VERSION)-linux-amd64 build/rpm/usr/local/bin/$(NAME)
	@ fpm -s dir -t rpm --name $(NAME) --version $(VERSION) --iteration $(shell git rev-list HEAD --count) \
		  --maintainer "subchen@gmail.com" --vendor "Guoqiang Chen" --license "Apache 2" \
		  --url "https://github.com/subchen/frep" \
		  --description "Generate file using template" \
		  -C build/rpm/ \
		  --package ./releases/

deb: build-linux
	@ mkdir -p build/deb/usr/local/bin/
	@ cp -f releases/$(NAME)-$(VERSION)-linux-amd64 build/deb/usr/local/bin/$(NAME)
	@ fpm -s dir -t deb --name $(NAME) --version $(VERSION) --iteration $(shell git rev-list HEAD --count) \
		  --maintainer "subchen@gmail.com" --vendor "Guoqiang Chen" --license "Apache 2" \
		  --url "https://github.com/subchen/frep" \
		  --description "Generate file using template" \
		  -C build/deb/ \
		  --package ./releases/

docker:
	docker login -u subchen -p "$(DOCKER_PASSWORD)"
	docker build -t subchen/$(NAME):$(VERSION) .
	docker tag subchen/$(NAME):$(VERSION) subchen/$(NAME):latest
	docker push subchen/$(NAME):$(VERSION)
	docker push subchen/$(NAME):latest

sha256sum: build
	@ for f in $(shell ls ./releases); do \
		cd $(CWD)/releases; sha256sum "$$f" >> $$f.sha256; \
	done

release: sha256sum

