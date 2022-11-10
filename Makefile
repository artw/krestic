tag := artw/krestic
dockerfiles := $(wildcard Dockerfile.*)

.PHONY: build
build:
	@$(foreach dockerfile,$(dockerfiles),\
		 docker buildx build --platform=linux/amd64,linux/arm64 -t ${tag}-`echo $(dockerfile) | cut -f2 -d.`:latest -f $(dockerfile) . --push; \
	)
