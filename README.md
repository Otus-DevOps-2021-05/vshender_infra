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

<details><summary>Details</summary>

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

</details>

In order to check the solution, you can see [the CI job result](https://github.com/Otus-DevOps-2021-05/vshender_infra/actions/workflows/run-tests.yml).


## Homework #6: cloud-testapp

- `yc` CLI utility was installed and configured.
- Installation and deployment scripts are created.
- The command to create a VM was added to the readme file.
- The metadata file that deploys the application on VM instance creation was created.

<details><summary>Details</summary>

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

$ yc compute instance list
+----------------------+------------+---------------+---------+-----------------+-------------+
|          ID          |    NAME    |    ZONE ID    | STATUS  |   EXTERNAL IP   | INTERNAL IP |
+----------------------+------------+---------------+---------+-----------------+-------------+
| epd5qtknrril3ndlhsrf | reddit-app | ru-central1-a | RUNNING | 178.154.224.203 | 10.129.0.34 |
+----------------------+------------+---------------+---------+-----------------+-------------+
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

</details>

In order to check the solution, you can see [the CI job result](https://github.com/Otus-DevOps-2021-05/vshender_infra/actions/workflows/run-tests.yml).


## Homework #7: packer-base

- A service account in Yandex Cloud was created and configured.
- A packer template for testapp base image is added.
- The packer template for testapp base image is parameterized.
- A packer template for testapp full image is added.

<details><summary>Details</summary>

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

Build a testapp base image using parameterized template:
```
$ packer build -var-file=variables.json ./ubuntu16.json
...
```

Build a testapp full image:
```
$ packer build -var-file=variables.json ./immutable.json
...
```

Create a VM instance using a full image:
```
$ ../config-scripts/create-reddit-vm.sh
...
```

</details>

In order to check the solution, you can see [the CI job result](https://github.com/Otus-DevOps-2021-05/vshender_infra/actions/workflows/run-tests.yml).


## Homework #8: terraform-1

- The VM isntance was created using Terraform.
- The output variable for an external IP address was added.
- The provisioners for the application deployment were added.
- Input variables were used for the configuration.
- The network load balancer was created.

<details><summary>Details</summary>

[Yandex.Cloud provider documentation](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs)

Get config for yandex provider:
```
$ yc config list
token: ...
cloud-id: ...
folder-id: ...
compute-default-zone: ru-central1-a
```

Initialize provider plugins:
```
$ cd terraform

$ terraform init

Initializing the backend...

Initializing provider plugins...
- Checking for available provider plugins...
- Downloading plugin for provider "yandex" (terraform-providers/yandex) 0.35.0...

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

See execution plan, showing what actions Terraform would take to apply the current configuration:
```
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance.app will be created
  + resource "yandex_compute_instance" "app" {
  ...
  }

Plan: 1 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```

Create a VM instance using terraform:
```
$ terraform apply -auto-approve
yandex_compute_instance.app: Creating...
yandex_compute_instance.app: Still creating... [10s elapsed]
yandex_compute_instance.app: Still creating... [20s elapsed]
yandex_compute_instance.app: Still creating... [30s elapsed]
yandex_compute_instance.app: Still creating... [40s elapsed]
yandex_compute_instance.app: Creation complete after 42s [id=fhmcpqriqgm182kto33a]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

$ ls
main.tf                  terraform.tfstate        terraform.tfstate.backup
```

Get an external IP address of the created VM using `terraform show` command:
```
$ terraform show | grep nat_ip_address
          nat_ip_address = "178.154.252.33"
```

Connect to the created VM:
```
$ ssh ubuntu@178.154.252.33
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)
...
```

Add the `external_ip_address_app` output variable and refresh the state:
```
$ terraform refresh
yandex_compute_instance.app: Refreshing state... [id=fhmmi8jnaat1655k0ljq]

Outputs:

external_ip_address_app = 178.154.252.33

$ terraform output
external_ip_address_app = 178.154.252.33

$ terraform output external_ip_address_app
178.154.252.33
```

Add [provisioners](https://www.terraform.io/docs/language/resources/provisioners/syntax.html) for the application deployment and recreate the VM:
```
$ terraform taint yandex_compute_instance.app
Resource instance yandex_compute_instance.app has been marked as tainted.

$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

yandex_compute_instance.app: Refreshing state... [id=fhmmi8jnaat1655k0ljq]

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # yandex_compute_instance.app is tainted, so must be replaced
-/+ resource "yandex_compute_instance" "app" {
      ...
    }

Plan: 1 to add, 0 to change, 1 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.

$ terraform apply -auto-approve
yandex_compute_instance.app: Refreshing state... [id=fhmbgbhkre7lfu7mcdl2]
yandex_compute_instance.app: Destroying... [id=fhmbgbhkre7lfu7mcdl2]
yandex_compute_instance.app: Still destroying... [id=fhmbgbhkre7lfu7mcdl2, 10s elapsed]
yandex_compute_instance.app: Destruction complete after 10s
yandex_compute_instance.app: Creating...
yandex_compute_instance.app: Still creating... [10s elapsed]
yandex_compute_instance.app: Still creating... [21s elapsed]
yandex_compute_instance.app: Still creating... [31s elapsed]
yandex_compute_instance.app: Still creating... [41s elapsed]
yandex_compute_instance.app: Provisioning with 'file'...
yandex_compute_instance.app: Still creating... [51s elapsed]
yandex_compute_instance.app: Still creating... [1m1s elapsed]
yandex_compute_instance.app: Provisioning with 'remote-exec'...
yandex_compute_instance.app (remote-exec): Connecting to remote host via SSH...
yandex_compute_instance.app (remote-exec):   Host: 178.154.240.24
yandex_compute_instance.app (remote-exec):   User: ubuntu
yandex_compute_instance.app (remote-exec):   Password: false
yandex_compute_instance.app (remote-exec):   Private key: true
yandex_compute_instance.app (remote-exec):   Certificate: false
yandex_compute_instance.app (remote-exec):   SSH Agent: false
yandex_compute_instance.app (remote-exec):   Checking Host Key: false
yandex_compute_instance.app (remote-exec): Connected!
...
yandex_compute_instance.app: Creation complete after 1m46s [id=fhmk1922pqdne0hd2ghg]

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

Outputs:

external_ip_address_app = 178.154.240.24
```

Open http://178.154.240.24:9292/ and check the application.

Use input variables for the configuration and recreate the VM:
```
$ terraform destroy -auto-approve
yandex_compute_instance.app: Refreshing state... [id=fhmk1922pqdne0hd2ghg]
yandex_compute_instance.app: Destroying... [id=fhmk1922pqdne0hd2ghg]
yandex_compute_instance.app: Destruction complete after 9s

Destroy complete! Resources: 1 destroyed.

$ terraform apply -auto-approve
...
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = 178.154.240.24
```

Add a network load balancer (see [yandex_lb_network_load_balancer](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/lb_network_load_balancer) and [yandex_lb_target_group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/lb_target_group)):
```
$ terraform apply -auto-approve
yandex_compute_instance.app: Refreshing state... [id=fhmeo4rot527qnsssigv]
yandex_lb_target_group.app_lb_target_group: Creating...
yandex_lb_target_group.app_lb_target_group: Creation complete after 3s [id=enpint9vuufj268oe7q3]
yandex_lb_network_load_balancer.app_lb: Creating...
yandex_lb_network_load_balancer.app_lb: Still creating... [10s elapsed]
yandex_lb_network_load_balancer.app_lb: Creation complete after 18s [id=b7ruppfn9ugmq564gonm]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = 178.154.240.24
lb_ip_address = 84.201.158.38
```

Open http://84.201.158.38/ and check the application.

</details>
