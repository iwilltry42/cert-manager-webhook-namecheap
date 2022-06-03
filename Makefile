OS ?= $(shell go env GOOS)
ARCH ?= $(shell go env GOARCH)

IMAGE_NAME := cert-manager-webhook-namecheap
IMAGE_TAG := $(shell git describe --dirty)
REPO_NAME := iwilltry42
PLATFORMS := linux/amd64,linux/arm64

OUT := $(shell pwd)/_out

KUBE_VERSION := v1.23.1

$(shell mkdir -p "$(OUT)")
export TEST_ASSET_ETCD=_test/kubebuilder/bin/etcd
export TEST_ASSET_KUBE_APISERVER=_test/kubebuilder/bin/kube-apiserver
export TEST_ASSET_KUBECTL=_test/kubebuilder/bin/kubectl

test: _test/kubebuilder
	go test -v .

_test/kubebuilder:
	curl -fsSL https://go.kubebuilder.io/test-tools/$(KUBE_VERSION)/$(OS)/$(ARCH) -o kubebuilder-tools.tar.gz
	mkdir -p _test/kubebuilder
	tar -xvf kubebuilder-tools.tar.gz
	mv kubebuilder/bin _test/kubebuilder/
	rm kubebuilder-tools.tar.gz
	rm -R kubebuilder

clean: clean-kubebuilder

clean-kubebuilder:
	rm -Rf _test/kubebuilder

tag:
	docker buildx build --platform $(PLATFORMS) -t "$(REPO_NAME)/$(IMAGE_NAME):latest" .
	docker buildx build --platform $(PLATFORMS) -t "$(REPO_NAME)/$(IMAGE_NAME):$(IMAGE_TAG)" .

push:
	docker buildx build --push --platform $(PLATFORMS) -t "$(REPO_NAME)/$(IMAGE_NAME):latest" .
	docker buildx build --push --platform $(PLATFORMS) -t "$(REPO_NAME)/$(IMAGE_NAME):$(IMAGE_TAG)" .


.PHONY: rendered-manifest.yaml
rendered-manifest.yaml:
	helm template \
	    --name ${IMAGE_NAME} \
        --set image.repository=$(IMAGE_NAME) \
        --set image.tag=$(IMAGE_TAG) \
        deploy/${IMAGE_NAME} > "$(OUT)/rendered-manifest.yaml"
