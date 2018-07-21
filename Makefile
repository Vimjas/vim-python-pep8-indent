test:
	VIMRUNNER_REUSE_SERVER=1 xvfb-run bundle exec rspec

test_slow:
	VIMRUNNER_REUSE_SERVER=0 bundle exec rspec

test_visible:
	VIMRUNNER_REUSE_SERVER=1 bundle exec rspec

# Run tests in dockerized Vims.
DOCKER_REPO:=blueyed/vim-python-pep8-indent-vims-for-test
DOCKER_TAG:=1
DOCKER_IMAGE:=$(DOCKER_REPO):$(DOCKER_TAG)

docker_image:
	docker build -t $(DOCKER_REPO):$(DOCKER_TAG) .
docker_push:
	docker push $(DOCKER_REPO):$(DOCKER_TAG)
docker_update_latest:
	docker tag $(DOCKER_REPO):$(DOCKER_TAG) $(DOCKER_REPO):latest
	docker push $(DOCKER_REPO):latest

test_docker: XVFB_ERRORFILE:=/dev/null
test_docker:
	@set -x; export DISPLAY=$(if $(VIMRUNNER_TEST_DISPLAY),$(VIMRUNNER_TEST_DISPLAY),172.17.0.1:99; Xvfb -ac -listen tcp :99 >$(XVFB_ERRORFILE) 2>&1 & XVFB_PID=$$!); \
	  docker run --rm -ti -e DISPLAY -e VIMRUNNER_REUSE_SERVER=1 \
	  -v $(CURDIR):/vim-python-pep8-indent $(DOCKER_IMAGE) $(RSPEC_ARGS) \
	  $(if $(VIMRUNNER_TEST_DISPLAY),,; ret=$$?; kill $$XVFB_PID; exit $$ret)
