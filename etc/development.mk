
.PHONY: cli
cli: .devtools ##@development Opens a command line interface with development tools.
	docker run -ti --rm \
		--dns 10.96.0.10 --dns-search container-image-builder.svc.cluster.local \
		-e DOCKER_HOST=tcp://docker:2375 \
		-e CACHE_ENDPOINT_SERVER=minio \
		-e CACHE_ENDPOINT_PORT=9000 \
		-e CACHE_BUCKET=image-layers \
		-e CACHE_ACCESS_KEY=8Q9U4RBHKKB6HU70SRZ1 \
		-e CACHE_SECRET_KEY=oxxT2iqBlW6lgaDVe8ll6mP8z/OSVIUnn9cB4+Q0 \
		-v $(PWD):/project -w /project \
		utopiaplanitia/docker-image-builder-devtools:latest sh

.PHONY: deploy
deploy: .devtools .dispatcher .worker ##@development Deploys the current code.
	kubectl apply -f kubernetes/namespace.yaml -f kubernetes
	./etc/restart-pods.sh

.PHONY: redeploy
redeploy: .devtools-deploy .dispatcher-deploy .worker-deploy ##@development Redeploys changed code.
	kubectl apply -f kubernetes/mirror.yaml -f kubernetes/minio.yaml
	./etc/await-pods.sh

.devtools-deploy: .devtools kubernetes/devtools.yaml
	kubectl apply -f kubernetes/devtools.yaml
	kubectl -n container-image-builder delete po -l app=devtools
	touch .devtools-deploy

.dispatcher-deploy: .dispatcher kubernetes/dispatcher.yaml
	kubectl apply -f kubernetes/dispatcher.yaml
	kubectl -n container-image-builder delete po -l app=dispatcher
	touch .dispatcher-deploy

.worker-deploy: .worker kubernetes/builders.yaml
	kubectl apply -f kubernetes/builders.yaml
	kubectl -n container-image-builder delete po -l app=builder
	touch .worker-deploy

.devtools: $(shell find devtools -type f)
	docker build -t utopiaplanitia/docker-image-builder-devtools:latest devtools
	touch .devtools

.dispatcher: $(shell find dispatcher -type f)
	docker build -t utopiaplanitia/docker-image-builder-dispatcher:latest dispatcher
	touch .dispatcher

.worker: $(shell find worker -type f)
	docker build -t utopiaplanitia/docker-image-builder-worker:latest worker
	touch .worker
