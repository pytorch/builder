DIR:=$(strip $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))

.PHONY: build-image
build-image: requirements.txt manage.py
	docker build -t pytorch/sync_s3_thirdparty_deps "$(DIR)"

.PHONY: push-image
push-image: build-image
	docker push pytorch/sync_s3_thirdparty_deps
