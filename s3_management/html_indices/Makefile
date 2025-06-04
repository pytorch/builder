DIR:=$(strip $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))

.PHONY: build-image
build-image: requirements.txt manage.py
	docker build -t pytorch/manage_s3_html "$(DIR)"

.PHONY: push-image
push-image: build-image
	docker push pytorch/manage_s3_html
