# vshender_infra

vshender Infra repository

## Homework #4: play-travis

- Pre-commit hook was added.
- Github PR template was added.
- Slack integration was enabled.
- Github actions were added.
- The Python test was fixed.

In order to check the solution, you can see [the CI job result](https://github.com/Otus-DevOps-2021-05/vshender_infra/actions/workflows/run-tests.yml).


## Homework #5: cloud-bastion

- Yandex Cloud account was created.
- Two VMs (`bastion` and `someinternalhost`) were created.
- Connection to `someinternalhost` via `bastion` was configured.
- Connection to `someinternalhost` via VPN was configured (based on Pritunl).
- SSL certificate was configured using Let's Encrypt.

Host IP addresses:
```
bastion_IP = 130.193.53.59
someinternalhost_IP = 10.129.0.16
```

The command to generate SSH authentication keys:
```
ssh-keygen -t rsa -f ~/.ssh/appuser -C appuser -P ""
```

Connect to the `bastion` host:
```
$ ssh -i ~/.ssh/appuser appuser@130.193.53.59
Welcome to Ubuntu 20.04.2 LTS (GNU/Linux 5.4.0-42-generic x86_64)
...
appuser@bastion:~$
```

Connect to the `someinternalhost` via the `bastion` using agent forwarding:
```
$ ssh-add ~/.ssh/appuser
Identity added: /Users/vshender/.ssh/appuser (appuser)

$ ssh -A appuser@130.193.53.59
Welcome to Ubuntu 20.04.2 LTS (GNU/Linux 5.4.0-42-generic x86_64)
...

appuser@bastion:~$ ssh 10.129.0.16
Welcome to Ubuntu 20.04.2 LTS (GNU/Linux 5.4.0-42-generic x86_64)
...

appuser@someinternalhost:~$
```

To directly access the internal host via the bastion host the following command can be used:
```
$ ssh -A -t appuser@130.193.53.59 ssh 10.129.0.16
Welcome to Ubuntu 20.04.2 LTS (GNU/Linux 5.4.0-42-generic x86_64)
...

appuser@someinternalhost:~$
```

Contents of the `.ssh/config` file for accessing the hosts using aliases:
```
Host bastion
    Hostname 130.193.53.59
    User appuser
    IdentityFile ~/.ssh/appuser

Host someinternalhost
    User appuser
    IdentityFile ~/.ssh/appuser
    ProxyCommand ssh -q bastion nc -q0 10.129.0.16 22
```

Install and setup Pritunl:
```
$ scp VPN/setupvpn.sh bastion:/home/appuser

$ ssh bastion
Welcome to Ubuntu 20.04.2 LTS (GNU/Linux 5.4.0-42-generic x86_64)
...

appuser@bastion:~$ sudo ./setupvpn.sh
...

appuser@bastion:~$ # open in browser http://130.193.53.59/setup

appuser@bastion:~$ sudo pritunl setup-key
...

appuser@bastion:~$ sudo pritunl default-password
Administrator default password:
  username: "pritunl"
  password: "..."

```

Pritunl user:
- username: test
- PIN: 6214157507237678334670591556762

See [Connecting to a Pritunl vpn server](https://docs.pritunl.com/docs/connecting) for instructions.

To setup Let's Encrypt for Pritunl admin panel just enter "130-193-53-59.sslip.io" in "Settings -> Lets Encrypt Domain".

In order to check the solution, you can see [the CI job result](https://github.com/Otus-DevOps-2021-05/vshender_infra/actions/workflows/run-tests.yml).


## Homework #6: cloud-testapp

- `yc` CLI utility was installed and configured.
- Installation and deployment scripts are created.
- The command to create a VM was added to the readme file.
- The metadata file that deploys the application on VM instance creation was created.


Related Yandex Cloud documentation:

- [Install CLI](https://cloud.yandex.ru/docs/cli/operations/install-cli)
- [Profile Create](https://cloud.yandex.ru/docs/cli/operations/profile/profile-create)

Check `yc` configuration:
```
$ yc config list
token: ...
cloud-id: ...
folder-id: ...
compute-default-zone: ru-central1-a

$ yc config profile list
default ACTIVE
```

Create a new VM instance:
```
$ yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --ssh-key ~/.ssh/appuser.pub
...
```

The created host's IP address and port:
```
testapp_IP = 178.154.224.203
testapp_port = 9292
```

Install dependencies and deploy the application:
```
$ scp config-scripts/*.sh yc-user@178.154.224.203:/home/yc-user
...

$ ssh yc-user@178.154.224.203
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)
...

yc-user@reddit-app:~$ ./install_ruby.sh
...

yc-user@reddit-app:~$ ruby -v
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]

yc-user@reddit-app:~$ bundler -v
Bundler version 1.11.2

yc-user@reddit-app:~$ ./install_mongodb.sh
...

yc-user@reddit-app:~$ sudo systemctl status mongod
● mongod.service - MongoDB Database Server
   Loaded: loaded (/lib/systemd/system/mongod.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2021-07-12 17:01:24 UTC; 12s ago
...

yc-user@reddit-app:~$ ./deploy.sh
...
```

Create a new VM instance providing metadata that deploys the application:
```
$ yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --metadata-from-file user-data=config-scripts/metadata.yaml
...
```

In order to check the solution, you can see [the CI job result](https://github.com/Otus-DevOps-2021-05/vshender_infra/actions/workflows/run-tests.yml).


## Homework #7: packer-base

- A service account in Yandex Cloud was created and configured.
- A packer template for testapp base image is added.

Create a Yandex Cloud service account, grant it access to the folder, and generate an IAM key:
```
$ SVC_ACCOUNT=svc

$ FOLDER_ID=$(yc config list | grep ^folder-id | awk '{ print $2 }')

$ yc iam service-account create --name $SVC_ACCOUNT --folder-id $FOLDER_ID
id: ajeg1tbs3ho02l5u4tg0
folder_id: b1gd4td7jk7gdlac0laf
created_at: "2021-07-13T09:50:41.522298119Z"
name: svc

$ ACCOUNT_ID=$(yc iam service-account get $SVC_ACCOUNT | grep ^id | awk '{ print $2 }')

$ yc resource-manager folder add-access-binding --id $FOLDER_ID \
    --role editor \
    --service-account-id $ACCOUNT_ID
done (1s)

$ yc iam key create --service-account-id $ACCOUNT_ID --output yc-svc-key.json
id: ajeqipnvev31urbod1dv
service_account_id: ajeg1tbs3ho02l5u4tg0
created_at: "2021-07-13T09:56:23.667310740Z"
key_algorithm: RSA_2048
```

Build a testapp base image:
```
$ cd packer

$ packer validate ./ubuntu16.json

$ packer build ./ubuntu16.json

$ yc compute image list
yandex: output will be in this color.

==> yandex: Creating temporary ssh key for instance...
==> yandex: Using as source image: fd869u2laf181s38k2cr (name: "ubuntu-1604-lts-1612430962", family: "ubuntu-1604-lts")
==> yandex: Creating network...
==> yandex: Creating subnet in zone "ru-central1-a"...
==> yandex: Creating disk...
==> yandex: Creating instance...
==> yandex: Waiting for instance with id fhmisb58df44oorun9s9 to become active...
    yandex: Detected instance IP: 178.154.227.237
==> yandex: Using SSH communicator to connect: 178.154.227.237
==> yandex: Waiting for SSH to become available...
==> yandex: Connected to SSH!
==> yandex: Provisioning with shell script: scripts/install_ruby.sh
...
==> yandex: Stopping instance...
==> yandex: Deleting instance...
    yandex: Instance has been deleted!
==> yandex: Creating image: reddit-base-1626203343
==> yandex: Waiting for image to complete...
==> yandex: Success image create...
==> yandex: Destroying subnet...
    yandex: Subnet has been deleted!
==> yandex: Destroying network...
    yandex: Network has been deleted!
==> yandex: Destroying boot disk...
    yandex: Disk has been deleted!
Build 'yandex' finished after 4 minutes 52 seconds.

==> Wait completed after 4 minutes 52 seconds

==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: reddit-base-1626203343 (id: fd8odftu99akenf9npl8) with family name reddit-base

$ yc compute image list
+----------------------+------------------------+-------------+----------------------+--------+
|          ID          |          NAME          |   FAMILY    |     PRODUCT IDS      | STATUS |
+----------------------+------------------------+-------------+----------------------+--------+
| fd8odftu99akenf9npl8 | reddit-base-1626203343 | reddit-base | f2el9g14ih63bjul3ed3 | READY  |
+----------------------+------------------------+-------------+----------------------+--------+
```
