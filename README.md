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
- The second VM instance was created.
- The `count` parameter was used in order to create two app instances.

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

Add a second VM instance:
```
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

yandex_compute_instance.app: Refreshing state... [id=fhmeo4rot527qnsssigv]
yandex_lb_target_group.app_lb_target_group: Refreshing state... [id=enpint9vuufj268oe7q3]
yandex_lb_network_load_balancer.app_lb: Refreshing state... [id=b7ruppfn9ugmq564gonm]

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create
  ~ update in-place

Terraform will perform the following actions:

  # yandex_compute_instance.app2 will be created
  + resource "yandex_compute_instance" "app2" {
      ...
    }

  # yandex_lb_target_group.app_lb_target_group will be updated in-place
  ~ resource "yandex_lb_target_group" "app_lb_target_group" {
        created_at = "2021-07-18T13:58:38Z"
        folder_id  = "b1gd4td7jk7gdlac0laf"
        id         = "enpint9vuufj268oe7q3"
        labels     = {}
        name       = "app-lb-target-group"
        region_id  = "ru-central1"

        target {
            address   = "10.128.0.18"
            subnet_id = "e9b4gc5qqhfpoe63kt9p"
        }
      + target {
          + address   = (known after apply)
          + subnet_id = "e9b4gc5qqhfpoe63kt9p"
        }
    }

Plan: 1 to add, 1 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.

$ terraform apply -auto-approve
yandex_compute_instance.app: Refreshing state... [id=fhmeo4rot527qnsssigv]
yandex_lb_target_group.app_lb_target_group: Refreshing state... [id=enpint9vuufj268oe7q3]
yandex_lb_network_load_balancer.app_lb: Refreshing state... [id=b7ruppfn9ugmq564gonm]
yandex_compute_instance.app2: Creating...
yandex_compute_instance.app2: Still creating... [10s elapsed]
yandex_compute_instance.app2: Still creating... [20s elapsed]
yandex_compute_instance.app2: Still creating... [30s elapsed]
yandex_compute_instance.app2: Still creating... [40s elapsed]
yandex_compute_instance.app2: Provisioning with 'file'...
yandex_compute_instance.app2: Still creating... [50s elapsed]
yandex_compute_instance.app2: Still creating... [1m0s elapsed]
yandex_compute_instance.app2: Provisioning with 'remote-exec'...
...
yandex_compute_instance.app2: Creation complete after 1m48s [id=fhmsgrkurrkqena67in5]
yandex_lb_target_group.app_lb_target_group: Modifying... [id=enpint9vuufj268oe7q3]
yandex_lb_target_group.app_lb_target_group: Modifications complete after 7s [id=enpint9vuufj268oe7q3]

Apply complete! Resources: 1 added, 1 changed, 0 destroyed.

Outputs:

external_ip_address_app = 178.154.240.24
external_ip_address_app2 = 84.201.175.185
lb_ip_address = 84.201.158.38
```

Use the `count` parameter to create app instances (see [dynamic Blocks](https://www.terraform.io/docs/language/expressions/dynamic-blocks.html)):
```
$ terraform apply -auto-approve
yandex_compute_instance.app2: Refreshing state... [id=fhmsgrkurrkqena67in5]
yandex_compute_instance.app[0]: Refreshing state... [id=fhmeo4rot527qnsssigv]
yandex_lb_target_group.app_lb_target_group: Refreshing state... [id=enpint9vuufj268oe7q3]
yandex_lb_network_load_balancer.app_lb: Refreshing state... [id=b7ruppfn9ugmq564gonm]
yandex_compute_instance.app2: Destroying... [id=fhmsgrkurrkqena67in5]
yandex_compute_instance.app[1]: Creating...
yandex_compute_instance.app[0]: Modifying... [id=fhmeo4rot527qnsssigv]
yandex_compute_instance.app[0]: Modifications complete after 3s [id=fhmeo4rot527qnsssigv]
yandex_compute_instance.app2: Still destroying... [id=fhmsgrkurrkqena67in5, 10s elapsed]
yandex_compute_instance.app[1]: Still creating... [10s elapsed]
yandex_compute_instance.app2: Destruction complete after 11s
yandex_compute_instance.app[1]: Still creating... [20s elapsed]
yandex_compute_instance.app[1]: Still creating... [30s elapsed]
yandex_compute_instance.app[1]: Still creating... [40s elapsed]
yandex_compute_instance.app[1]: Provisioning with 'file'...
yandex_compute_instance.app[1]: Still creating... [50s elapsed]
yandex_compute_instance.app[1]: Still creating... [1m0s elapsed]
yandex_compute_instance.app[1]: Provisioning with 'remote-exec'...
...
yandex_compute_instance.app[1]: Creation complete after 1m42s [id=fhmga03s2qu3frlhk0s7]
yandex_lb_target_group.app_lb_target_group: Modifying... [id=enpint9vuufj268oe7q3]
yandex_lb_target_group.app_lb_target_group: Modifications complete after 8s [id=enpint9vuufj268oe7q3]

Apply complete! Resources: 1 added, 2 changed, 1 destroyed.

Outputs:

external_ip_address_app = [
  "178.154.240.24",
  "178.154.230.155",
]
lb_ip_address = 84.201.158.38
```

</details>

In order to check the solution, you can see [the CI job result](https://github.com/Otus-DevOps-2021-05/vshender_infra/actions/workflows/run-tests.yml).


## Homework #9: terraform-2

- The separate network for the app VM instance is created.
- New base images for the DB and the application are created.
- The separate VM instances were created for DB and the application.
- The infrastructure definition was refactored using modules.
- The `prod` and `stage` infrastructures are created.
- The "s3" backend is used to store terraform state in an object bucket.
- The provisioners disabling is implemented.

<details><summary>Details</summary>

Create a separate nework for the app VM instance:
```
$ cd terraform

$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance.app[0] will be created
  + resource "yandex_compute_instance" "app" {
      ...
    }

  # yandex_vpc_network.app_network will be created
  + resource "yandex_vpc_network" "app_network" {
      ...
    }

  # yandex_vpc_subnet.app_subnet will be created
  + resource "yandex_vpc_subnet" "app_subnet" {
      ...
    }

Plan: 3 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.


$ terraform apply -auto-approve
yandex_vpc_network.app_network: Creating...
yandex_vpc_network.app_network: Creation complete after 2s [id=enpe8ba80a5osb22ggbm]
yandex_vpc_subnet.app_subnet: Creating...
yandex_vpc_subnet.app_subnet: Creation complete after 1s [id=e9bni16d9r18hkaofgnc]
yandex_compute_instance.app[0]: Creating...
...
yandex_compute_instance.app[0]: Creation complete after 1m41s [id=fhmm35i78kr6aq00fm98]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = [
  "193.32.218.54",
]

$ terraform destroy -auto-approve
...

Destroy complete! Resources: 3 destroyed.
```

Create base images for the DB and the application:
```
$ cd ../packer

$ packer build -var-file=variables.json ./db.json
...
==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: reddit-db-base-1626779578 (id: fd8cduv3d4pgtgifqsl0) with family name reddit-db-base

$ packer build -var-file=variables.json ./app.json
...
==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: reddit-app-base-1626779801 (id: fd83k16ogu4j0ku96e60) with family name reddit-app-base
```

Create separate VM instances for DB and the application:
```
$ terraform apply -auto-approve
yandex_vpc_network.app_network: Creating...
yandex_vpc_network.app_network: Creation complete after 2s [id=enp7grh17psar0uvrnfv]
yandex_vpc_subnet.app_subnet: Creating...
yandex_vpc_subnet.app_subnet: Creation complete after 1s [id=e9bkmii0jrolt2fo028f]
yandex_compute_instance.app: Creating...
yandex_compute_instance.db: Creating...
...
yandex_compute_instance.app: Creation complete after 1m4s [id=fhmk0h7cqspro2ahgsef]
yandex_compute_instance.db: Still creating... [1m10s elapsed]
yandex_compute_instance.db: Still creating... [1m20s elapsed]
yandex_compute_instance.db: Still creating... [1m30s elapsed]
yandex_compute_instance.db: Creation complete after 1m32s [id=fhmvnjf5m9sif3j00c7p]
null_resource.app_provisioning: Creating...
null_resource.db_provisioning: Creating...
...
null_resource.app_provisioning: Still creating... [30s elapsed]
null_resource.db_provisioning: Still creating... [30s elapsed]
null_resource.app_provisioning: Creation complete after 30s [id=6623979293027793107]
null_resource.db_provisioning: Provisioning with 'remote-exec'...
null_resource.db_provisioning (remote-exec): Connecting to remote host via SSH...
null_resource.db_provisioning (remote-exec):   Host: 178.154.223.159
null_resource.db_provisioning (remote-exec):   User: ubuntu
null_resource.db_provisioning (remote-exec):   Password: false
null_resource.db_provisioning (remote-exec):   Private key: true
null_resource.db_provisioning (remote-exec):   Certificate: false
null_resource.db_provisioning (remote-exec):   SSH Agent: false
null_resource.db_provisioning (remote-exec):   Checking Host Key: false
null_resource.db_provisioning (remote-exec): Connected!
null_resource.db_provisioning: Creation complete after 32s [id=8790677782413716257]

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = 178.154.223.251

```

Open http://178.154.223.251/ and check the application.

Destroy the infrastructure:
```
$ terraform destroy -auto-approve
...

Destroy complete! Resources: 6 destroyed.
```

Install the `app` and `db` modules:
```
$ terraform get
- app in modules/app
- db in modules/db
- vpc in modules/vpc

$ tree .terraform
.terraform
├── modules
│   └── modules.json
└── plugins
    └── darwin_amd64
        ├── lock.json
        ├── terraform-provider-null_v3.1.0_x5
        └── terraform-provider-yandex_v0.35.0_x4

3 directories, 4 files

$ cat .terraform/modules/modules.json | jq
{
  "Modules": [
    {
      "Key": "",
      "Source": "",
      "Dir": "."
    },
    {
      "Key": "app",
      "Source": "./modules/app",
      "Dir": "modules/app"
    },
    {
      "Key": "db",
      "Source": "./modules/db",
      "Dir": "modules/db"
    },
    {
      "Key": "vpc",
      "Source": "./modules/vpc",
      "Dir": "modules/vpc"
    }
  ]
}
```

Create VM instances for DB and the application using modules:
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

  # module.app.null_resource.app_provisioning will be created
  + resource "null_resource" "app_provisioning" {
      ...
    }

  # module.app.yandex_compute_instance.app will be created
  + resource "yandex_compute_instance" "app" {
      ...
    }

  # module.db.null_resource.db_provisioning will be created
  + resource "null_resource" "db_provisioning" {
      ...
    }

  # module.db.yandex_compute_instance.db will be created
  + resource "yandex_compute_instance" "db" {
      ...
    }

  # module.vpc.yandex_vpc_network.app_network will be created
  + resource "yandex_vpc_network" "app_network" {
      ...
    }

  # module.vpc.yandex_vpc_subnet.app_subnet will be created
  + resource "yandex_vpc_subnet" "app_subnet" {
     ...
    }

Plan: 6 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.

$ terraform apply -auto-approve
module.vpc.yandex_vpc_network.app_network: Creating...
module.vpc.yandex_vpc_network.app_network: Creation complete after 2s [id=enp1lqjh39d0bfcr4rq6]
module.vpc.yandex_vpc_subnet.app_subnet: Creating...
module.vpc.yandex_vpc_subnet.app_subnet: Creation complete after 1s [id=e9bhs3l0fe3jger5hrqq]
module.db.yandex_compute_instance.db: Creating...
module.app.yandex_compute_instance.app: Creating...
...
module.app.yandex_compute_instance.app: Creation complete after 42s [id=fhm8fj3ise895bqg0p7p]
module.db.yandex_compute_instance.db: Creation complete after 43s [id=fhmg874d5t3mkf4bcubq]
module.db.null_resource.db_provisioning: Creating...
module.app.null_resource.app_provisioning: Creating...
module.app.null_resource.app_provisioning: Provisioning with 'file'...
module.db.null_resource.db_provisioning: Provisioning with 'file'...
...
module.app.null_resource.app_provisioning: Provisioning with 'remote-exec'..
...
module.db.null_resource.db_provisioning: Provisioning with 'remote-exec'...
...
module.db.null_resource.db_provisioning: Creation complete after 28s [id=3645675801631671878]
...
module.app.null_resource.app_provisioning: Creation complete after 1m5s [id=2690869919208429348]

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = 178.154.223.58
external_ip_address_db = 178.154.223.241

$ terraform destroy -auto-approve
...

Destroy complete! Resources: 6 destroyed.
```

Check the `prod` infrastructure:
```
$ cd prod

$ terraform init
Initializing modules...
- app in ../modules/app
- db in ../modules/db
- vpc in ../modules/vpc

Initializing the backend...

Initializing provider plugins...
- Checking for available provider plugins...
- Downloading plugin for provider "null" (hashicorp/null) 3.1.0...
- Downloading plugin for provider "yandex" (terraform-providers/yandex) 0.35.0...

...

$ terraform apply -auto-approve
...

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = 178.154.220.6
external_ip_address_db = 178.154.222.215

$ terraform destroy -auto-approve
...

Destroy complete! Resources: 6 destroyed.

```

Check the `stage` infrastructure:
```
$ cd ../stage

$ terraform init
Initializing modules...
- app in ../modules/app
- db in ../modules/db
- vpc in ../modules/vpc

Initializing the backend...

Initializing provider plugins...
- Checking for available provider plugins...
- Downloading plugin for provider "null" (hashicorp/null) 3.1.0...
- Downloading plugin for provider "yandex" (terraform-providers/yandex) 0.35.0...

...

$ terraform apply -auto-approve
...

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = 178.154.221.50
external_ip_address_db = 178.154.223.253

$ terraform destroy -auto-approve
...

Destroy complete! Resources: 6 destroyed.

$ cd ..
```

Create a bucket for tfstate storage:
```
$ terraform init

Initializing the backend...

Initializing provider plugins...
- Checking for available provider plugins...
- Downloading plugin for provider "yandex" (terraform-providers/yandex) 0.35.0...

...

$ terraform apply -auto-approve
yandex_iam_service_account_static_access_key.sa_static_key: Creating...
yandex_iam_service_account_static_access_key.sa_static_key: Creation complete after 1s [id=aje6fabk26om8ai3umdt]
yandex_storage_bucket.tfstate_storage: Creating...
yandex_storage_bucket.tfstate_storage: Creation complete after 0s [id=otus-tfstate-storage]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

$ cd ..

```

Create `prod` and `stage` infrastructures saving the state in the object bucket:
```
$ cd prod

$ terraform init
terraform init
Initializing modules...

Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

...

$ terraform apply -auto-approve
...

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = 178.154.220.159
external_ip_address_db = 178.154.220.4

$ terraform destroy -auto-approve
...

Destroy complete! Resources: 6 destroyed.

$ cd ../stage

$ terraform init
terraform init
Initializing modules...

Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

...

$ terraform apply -auto-approve
...

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = 178.154.221.50
external_ip_address_db = 178.154.222.132

$ terraform destroy -auto-approve
...

Destroy complete! Resources: 6 destroyed.

$ cd ..

$ aws --endpoint-url=https://storage.yandexcloud.net s3 ls --recursive s3://otus-tfstate-storage
2021-07-26 19:49:32        157 prod/terraform.tfstate
2021-07-26 19:54:05        157 stage/terraform.tfstate
```

</details>

In order to check the solution, you can see [the CI job result](https://github.com/Otus-DevOps-2021-05/vshender_infra/actions/workflows/run-tests.yml).


## Homework #10: ansible-1

- Ansible was installed.
- A staging environment was created.
- The inventory file was added.
- Ansible was configured using `ansible.cfg` file.
- Host groups were added.
- The YAML inventory file was added.
- The servers' components were checked.
- The application repository was cloned to the app server.
- The application cloning playbook was added.

<details><summary>Details</summary>

Install Ansible:
```
$ cd ansible

$ pip install -r requirements.txt
...
Successfully installed MarkupSafe-2.0.1 ansible-4.4.0 ansible-core-2.11.3 cffi-1.14.6 cryptography-3.4.7 jinja2-3.0.1 packaging-21.0 pycparser-2.20 pyparsing-2.4.7 resolvelib-0.5.4

```

Create a staging environment:
```
$ cd ../terraform

$ terraform apply -auto-approve
yandex_iam_service_account_static_access_key.sa_static_key: Creating...
yandex_iam_service_account_static_access_key.sa_static_key: Creation complete after 2s [id=aje1apk11aev29omkkfm]
yandex_storage_bucket.tfstate_storage: Creating...
yandex_storage_bucket.tfstate_storage: Creation complete after 1s [id=otus-tfstate-storage]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

$ cd stage

$ terraform apply -auto-approve
...

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = 178.154.205.41
external_ip_address_db = 178.154.220.6

$ cd ../../ansible

```

Check the inventory file:
```
$ ansible appserver -i ./inventory -m ping
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}

$ ansible dbserver -i ./inventory -m ping
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}

```

Check the configuration from `ansible.cfg` file:
```
$ ansible appserver -m command -a uptime
appserver | CHANGED | rc=0 >>
 17:53:14 up  1:11,  1 user,  load average: 0.16, 0.03, 0.01

$ ansible dbserver -m command -a uptime
dbserver | CHANGED | rc=0 >>
 17:53:20 up  1:11,  1 user,  load average: 0.00, 0.00, 0.00

```

Check the host group:
```
$ ansible app -m ping
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}

```

Check the YAML inventory:
```
$ ansible all -i inventory -m ping
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Check the servers' components:
```
$ ansible app -m command -a 'ruby -v'
appserver | CHANGED | rc=0 >>
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]

$ ansible app -m command -a 'bundler -v'
appserver | CHANGED | rc=0 >>
Bundler version 1.11.2

$ ansible app -m command -a 'ruby -v; bundler -v'
appserver | FAILED | rc=1 >>
ruby: invalid option -;  (-h will show valid options) (RuntimeError)non-zero return code

$ ansible app -m shell -a 'ruby -v; bundler -v'
appserver | CHANGED | rc=0 >>
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
Bundler version 1.11.2

$ ansible db -m command -a 'systemctl status mongod'
dbserver | CHANGED | rc=0 >>
● mongod.service - MongoDB Database Server
   Loaded: loaded (/lib/systemd/system/mongod.service; enabled; vendor preset: enabled)
   Active: active (running) since Wed 2021-08-11 16:42:04 UTC; 6 days ago
     Docs: https://docs.mongodb.org/manual
 Main PID: 808 (mongod)
   CGroup: /system.slice/mongod.service
           └─808 /usr/bin/mongod --config /etc/mongod.conf

$ ansible db -m systemd -a name=mongod
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "name": "mongod",
    "status": {
        ...
    }
}

$ ansible db -m service -a name=mongod
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "name": "mongod",
    "status": {
        ...
    }
}
```

Clone the application repository:
```
$ ansible app -m git -a 'repo=https://github.com/express42/reddit.git dest=/home/ubuntu/reddit'
appserver | SUCCESS => {
    "after": "5c217c565c1122c5343dc0514c116ae816c17ca2",
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "before": "5c217c565c1122c5343dc0514c116ae816c17ca2",
    "changed": false,
    "remote_url_changed": false
}
```

Check the application cloning playbook:
```
$ ansible-playbook clone.yaml

PLAY [Clone] *****************************************************************************************************

TASK [Gathering Facts] *******************************************************************************************
ok: [appserver]

TASK [Clone repo] ************************************************************************************************
ok: [appserver]

PLAY RECAP *******************************************************************************************************
appserver                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
