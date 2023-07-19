# okd-deployment

Note on 4.12 and mirror-registry
When using mirror-registry as a local repository for OKD 4.12 as described in the release_mirror_with_ocmirror howto, the bootstrap node fails to pull some images. To work around this, login to the bootstrap node using the ssh key as the core user:

```sh
ssh -i mykey core@bootstrap.clustername.basedomain
 ```

Wait until the service release-image-pivot has failed.

```sh
systemctl status release-image-pivot.service
```

When that happens, a check of its logs reveals that it's lacking access to registry credentials. Install those:

```sh
cp /root/.docker/config.json /etc/ostree/auth.json
chmod a+r /etc/ostree/auth.json
``` 

Then simply start the release-image-pivot.service.

```sh
systemctl start release-image-pivot.service
```

It should do its work for a while, and your session should disconnect, as it causes the machine to reboot. Then the installation will move forward.