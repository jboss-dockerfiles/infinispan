RELEASE_NAME=9.2.3.Final
DRY_RUN=true
PUSH_ORIGIN=origin
SKIP_TESTS=false

_replace_version_in_dockerfile:
	sed -i "s/ENV INFINISPAN_VERSION.*/ENV INFINISPAN_VERSION $(RELEASE_NAME)/g" ./server/Dockerfile
.PHONY: _replace_version_in_dockerfile

_commit_changes:
	git commit -a -m "$(RELEASE_NAME) upgrade"
.PHONY: _commit_changes

_test:
ifeq ($(SKIP_TESTS), false)
	cd ci && ./ci_check.sh
	cd ci && ./ci_openshift.sh
else
	$(info SKIP_TESTS is set to true. Skipping...)
endif
.PHONY: _test

_tag_changes:
	git tag "$(RELEASE_NAME)"
.PHONY: _tag_changes

_push_changes:
ifeq ($(DRY_RUN), false)
	git push $(PUSH_ORIGIN)
else
	$(info DRY_RUN is set to true. Skipping...)
endif
.PHONY: _push_changes

release: _replace_version_in_dockerfile _test _commit_changes _tag_changes _push_changes
.PHONY: release


