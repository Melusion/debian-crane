# Crane

Ist von hier <https://github.com/google/go-containerregistry>

Das Teil kann remote an OCI-Registries arbeiten. Siehe auch <https://wiki.ad.hygi.de/pages/viewpage.action?pageId=88802815>.

```bash
crane delete xxx.cr.de-fra.ionos.com/os/devuan-excalibur@sha256:3accbb3556ba753d5539a45048a69670a17dee15a105877a18716d43b5601731
```

Löscht zB gemäß hash, auch wenn kein tag mehr am manifest hängt.

Leider finde ich _crane_ nicht in den offizielen Debian repositories.

...
