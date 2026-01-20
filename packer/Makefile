LOG_FILE := build.log
NODE_VERSION := 10.0.3-0

.PHONY: all
all: download-ami build-observability build-node

.PHONY: download-ami
download-ami:
	aws s3 cp s3://distribution.stagenet.concordium.com/deb/concordium-stagenet-node_$(NODE_VERSION)_amd64.deb ./concordium-node.deb

# Step to build the AMI image
.PHONY: build-observability
build-observability:
	@TIMESTAMP=$$(date +%Y%m%d%H%M%S) && \
	export IMAGE_NAME=concordium-observability-node-test-$${TIMESTAMP} && \
	packer build -var-file=observability/stagenet_variables.pkrvars.hcl -var ami_name=$$IMAGE_NAME observability | tee $(LOG_FILE) && \
	if [ $${PIPESTATUS[0]} -ne 0 ]; then exit 1; fi

.PHONY: build-node
build-node:
	@TIMESTAMP=$$(date +%Y%m%d%H%M%S) && \
	export IMAGE_NAME=stagenet-$${TIMESTAMP}-concordium-node-test-$${TIMESTAMP} && \
	export SOURCE_IMAGE_ID=$$(awk -F': ' '/eu-west-1:/ {print $$2}' $(LOG_FILE)) && \
	packer build -var-file=concordium-node/stagenet_variables.pkrvars.hcl -var source_ami_id=$$SOURCE_IMAGE_ID -var ami_name=$$IMAGE_NAME concordium-node
