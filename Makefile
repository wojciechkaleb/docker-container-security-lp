all: lint dockerlint_policies_check build_hugo_builder build_website trivy_scanner
# serve_website healthcheck clean

server_port = 1313
server_container_name := hugo_server_$(shell uuidgen)
healthcheck_start_period = 10

lint:
	@echo 'Linting using hadolint'
	@docker run --rm -v $(PWD)/hadolint.yml:/.config/hadolint.yml -i hadolint/hadolint < Dockerfile
	@echo "Linting completed"

dockerlint_policies_check: 
	@echo "Checking required policies"
	@docker run --rm -v $(PWD):/root/ -v /var/run/docker.sock:/var/run/docker.sock projectatomic/dockerfile-lint dockerfile_lint -f Dockerfile -r policies/security_rules.yml


build_hugo_builder: lint dockerlint_policies_check
	@echo "Building Hugo Builder container..."
	@docker build --no-cache \
		--build-arg BUILD_DATE=$$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
		--build-arg COMMIT_SHA=$$(git rev-parse HEAD) \
		--build-arg IMAGE_VERSION=$$(git rev-parse --short HEAD) \
		--build-arg BUILD_VERSION="0.0.1" \
		-t finshare/hugo-builder .
	@echo "Hugo Builder container built!"
	@docker images finshare/hugo-builder

build_website: build_hugo_builder
	@echo "Building website..."
	@docker container run -v $(PWD)/orgdocs:/src finshare/hugo-builder hugo
	@echo "Website builded!"

trivy_scanner: build_website
	@echo "Scanning immage"
	@docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(PWD)/analysis:/analysis aquasec/trivy image --format spdx-json --output /analysis/sbom.json --scanners vuln,secret,misconfig finshare/hugo-builder

# serve_website: build_website
# 	@echo "Serving website"
# 	@echo "Creating test container $(server_container_name)"
# 	@docker container run -d -v $(PWD)/orgdocs:/src -p $(server_port):$(server_port) --name $(server_container_name) finshare/hugo-builder hugo server -w --bind=0.0.0.0
	
# healthcheck: serve_website
# 	@echo "Performing healthcheck in $(healthcheck_start_period) seconds"
# 	@sleep $(healthcheck_start_period)
# 	@if [ "$$(docker inspect --format='{{.State.Health.Status}}' $(server_container_name))" != "healthy" ]; then \
# 		echo "Healthcheck failed: Container $(server_container_name) is not healthy"; \
# 		exit 1; \
# 	else \
# 		echo "Healthcheck passed: Container $(server_container_name) is healthy"; \
# 	fi
	
# clean: healthcheck
# 	@echo "Cleaning test container"
# 	@echo "Removing $(server_container_name)"
# 	@docker rm -f -v $(server_container_name)
# 	@echo "Cleanup completed."
	
.PHONY: all

