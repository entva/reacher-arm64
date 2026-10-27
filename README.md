# reacher-arm64

Builds a linux/arm64 Docker image of the Reacher backend
([reacherhq/check-if-email-exists](https://github.com/reacherhq/check-if-email-exists)) and
publishes it to GitHub Container Registry. Upstream ships no arm64 image, so this repo builds one
from an upstream release tag.

Image: `ghcr.io/entva/reacher-backend:<tag>` (for example `v0.11.10`), public.

Files:

- `Dockerfile`: two-stage build. Compiles `reacher_backend` on `rust:*-alpine`, then runs it on
  `alpine` with Chromium and chromedriver. It is copied into the upstream checkout at build time.
- `.github/workflows/build.yml`: manual workflow (`workflow_dispatch`) that checks out the
  upstream tag into `src/`, builds on a native arm64 runner, and pushes to ghcr.io.

## Publish a new version

1. Find the latest upstream release tag:
   ```
   gh release list -R reacherhq/check-if-email-exists -L 3
   ```
2. Check the tag builds. Build locally with the Dockerfile (needs Docker):
   ```
   git clone --depth 1 --branch <tag> https://github.com/reacherhq/check-if-email-exists /tmp/reacher-src
   cp Dockerfile /tmp/reacher-src/Dockerfile
   docker build --platform linux/arm64 -t reacher-backend:test /tmp/reacher-src
   ```
   If the build fails, fix the `Dockerfile` (for example missing Alpine packages for a new
   dependency) before continuing.
3. Run the workflow with that tag, then wait for it to finish:
   ```
   gh workflow run build.yml -f tag=<tag>
   gh run list -w build.yml -L 1
   gh run watch <run-id> --exit-status
   ```
   The image is pushed as `ghcr.io/entva/reacher-backend:<tag>`.
4. Verify the pull works without credentials:
   ```
   docker pull --platform linux/arm64 ghcr.io/entva/reacher-backend:<tag>
   ```

## Bump dependencies

Update these, then repeat the local build check above:

- Action versions in `build.yml`: check `gh release view -R <owner/repo>` for
  `actions/checkout`, `docker/setup-buildx-action`, `docker/login-action`,
  `docker/build-push-action`, and pin the major tag.
- Runner label in `build.yml` (`ubuntu-XX.04-arm`): see `actions/runner-images` for the newest
  arm64 image.
- Base images in `Dockerfile`: pinned to exact versions (`rust:<version>-alpine<version>` and
  `alpine:<version>`). Look up the latest on Docker Hub and confirm each tag exists with
  `docker manifest inspect <image>:<tag>`. Keep the Alpine versions of the two stages equal.

## Run the image

```
docker run --rm -p 8080:8080 ghcr.io/entva/reacher-backend:<tag>
```

Configuration uses `RCH__*` environment variables, see upstream docs.
