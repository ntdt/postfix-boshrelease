# BOSH Release for postfix

## Usage

To use this bosh release, first upload it to your bosh:

```
bosh target BOSH_HOST
git clone https://github.com/cloudfoundry-community/postfix-boshrelease.git
cd postfix-boshrelease
bosh upload release releases/postfix/postfix-1.yml
```

For [bosh-lite](https://github.com/cloudfoundry/bosh-lite), you can edit `templates/bosh-lite-example.yml` and change all the `XXX`es to suit your situation and then deploy.

```
mkdir tmp
cp templates/bosh-lite-example.yml tmp/manifest.yml
vi tmp/manifest.yml
bosh deploy -d postfix-warden tmp/manifest.yml
```
If you do not want to enable SASL, then delete the `sasl_users` parameter.  If you do not want to enable DKIM, then delete the `dkim_privatekey` parameter.  If you do want to use DKIM, then you will need to generate that key and make sure that the public part of it is in your DNS.  You can learn more about this here:  https://wiki.debian.org/opendkim

For AWS EC2, create a single VM:

```
templates/make_manifest aws-ec2
bosh -n deploy
```

### Override security groups

For AWS & Openstack, the default deployment assumes there is a `default` security group. If you wish to use a different security group(s) then you can pass in additional configuration when running `make_manifest` above.

Create a file `my-networking.yml`:

``` yaml
---
networks:
  - name: postfix1
    type: dynamic
    cloud_properties:
      security_groups:
        - postfix
```

Where `- postfix` means you wish to use an existing security group called `postfix`.

You now suffix this file path to the `make_manifest` command:

```
templates/make_manifest openstack-nova my-networking.yml
bosh -n deploy
```

### Development

As a developer of this release, create new releases and upload them:

```
bosh create release --force && bosh -n upload release
```

### Final releases

To share final releases:

```
bosh create release --final
```

By default the version number will be bumped to the next major number. You can specify alternate versions:


```
bosh create release --final --version 2.1
```

After the first release you need to contact [Dmitriy Kalinin](mailto://dkalinin@pivotal.io) to request your project is added to https://bosh.io/releases (as mentioned in README above).
