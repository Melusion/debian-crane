# debian-crane

Build a small internal Debian package for [`crane`](https://github.com/google/go-containerregistry), the command-line tool from Google's `go-containerregistry` project.

`crane` can work directly with remote OCI/container registries without requiring a local Docker daemon. This is useful for inspecting, copying, tagging and deleting container images in registries.

## Why this repository exists

At the time this package was created, `crane` was not available in the official Debian repositories used on our systems.

Instead of installing `crane` manually on every host, this repository builds a small Debian package from the official upstream GitHub release binary.

The resulting package can then be published to a private APT repository and installed on hosts that do not have direct internet access.

## Example use case

Delete an OCI image manifest by digest, even if no tag points to it anymore:

```bash
crane delete xxx.cr.de-fra.ionos.com/os/devuan-excalibur@sha256:3accbb3556ba753d5539a45048a69670a17dee15a105877a18716d43b5601731
```
