all: lint build_hugo_builder build_website serve_website healthcheck clean

server_port = 1313
server_container_name := hugo_server_$(shell uuidgen)
healthcheck_start_period = 10

lint:
	@echo 'Linting using hadolint'
	@docker run --rm -v $(PWD)/hadolint.yml:/.config/hadolint.yml -i hadolint/hadolint < Dockerfile
	@echo "Linting completed"

build_hugo_builder: lint
	@echo "Building Hugo Builder container..."
	@docker build -t finshare/hugo-builder .
	@echo "Hugo Builder container built!"
	@docker images finshare/hugo-builder

build_website: build_hugo_builder
	@echo "Building website..."
	@docker container run -v $(PWD)/orgdocs:/src finshare/hugo-builder hugo
	@echo "Website builded!"

serve_website: build_website
	@echo "Serving website"
	@echo "Creating test container $(server_container_name)"
	@docker container run -d -v $(PWD)/orgdocs:/src -p $(server_port):$(server_port) --name $(server_container_name) finshare/hugo-builder hugo server -w --bind=0.0.0.0
	
healthcheck: serve_website
	@echo "Performing healthcheck in $(healthcheck_start_period) seconds"
	@sleep $(healthcheck_start_period)
	@if [ "$$(docker inspect --format='{{.State.Health.Status}}' $(server_container_name))" != "healthy" ]; then \
		echo "Healthcheck failed: Container $(server_container_name) is not healthy"; \
		exit 1; \
	else \
		echo "Healthcheck passed: Container $(server_container_name) is healthy"; \
	fi
	
clean: healthcheck
	@echo "Cleaning test container"
	@echo "Removing $(server_container_name)"
	@docker rm -f -v $(server_container_name)
	@echo "Cleanup completed."
	
.PHONY: all

