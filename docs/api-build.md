# API Build System

## CI Build Process

We manage our own docker file to control the swift/linux environment to enable building a
swift binary in Github Actions that we can reliably deploy to our production VM.

This enables us to not build on the production VM, becuase compiling the swift vapor app
takes a tremendous amount of memory and CPU.

By managing our own docker image, we can control linux distro, and swift version and
dependencies, to ensure that the deployed binary will run exactly the same in the
production VM. Previous to this process, we had problems where the official swift docker
images drifted out of sync with our Ubuntu version, and caused hard-to-debug crashes.

The docker image is built from the `.github/workflows/docker-images.yml` workflow, which
creates a the custom image `ghcr.io/gertrude-app/api-ci-build:latest`.

The current (as of Dec 2025) production VM is running Ubuntu 24.04, which is reflected in
the build image. Should that ever change, we should update the base image.

The production VM does not need to have swift installed, as we statically link the swift
standard library. At the moment we do not do a FULLY static build, but we could explore
this in the future if desired. Fully static builds have significantly larger binary sizes,
but come with some advantages.

## Updating Swift Version

To update the swift version, change the `swiftly install` command to the new version in
`api/Dockerfile.ci`. Once it merges to master, the latest image will be rebuilt using the
new version, and the next ci workflow run will use the new image.
