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
