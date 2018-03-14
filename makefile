OUTPUT = main # will be archived
PACKAGED_TEMPLATE = packaged.yaml # will be archived
TEMPLATE = template.yaml
VERSION = 1.7
S3_BUCKET := $(S3_BUCKET)
ZIPFILE = lambda.zip

.PHONY: ci
ci: install lint test

.PHONY: test
test:
	go test ./...

.PHONY: clean
clean:
	rm -f $(OUTPUT)
	rm -f $(ZIPFILE)

.PHONY: install
install:
	go get -t ./...
	# go get -u honnef.co/go/tools/cmd/megacheck
	go get -u golang.org/x/lint/golint

local-install:
	go get -u github.com/awslabs/aws-sam-local

.PHONY: lint
lint: install
	# megacheck -go $(VERSION)
	golint -set_exit_status

main: ./cmd/main.go
	go build -o $(OUTPUT) ./cmd/main.go

# compile the code to run in Lambda (local or real)
.PHONY: lambda
lambda:
	GOOS=linux GOARCH=amd64 $(MAKE) main

# create a lambda deployment package
$(ZIPFILE): clean lambda
	zip -9 -r $(ZIPFILE) $(OUTPUT)

.PHONY: run-local
local-deploy: local-install
	aws-sam-local local start-api

.PHONY: build
build: clean lambda

# TODO: Encrypt package in S3 with --kms-key-id
.PHONY: package
package:
	aws cloudformation package --template-file $(TEMPLATE) --s3-bucket $(S3_BUCKET) --output-template-file $(PACKAGED_TEMPLATE)
