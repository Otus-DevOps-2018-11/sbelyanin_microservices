# sbelyanin_microservices
sbelyanin microservices repository

## HW №13

docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts --google-machine-type n1-standard-1 --google-zone europe-west1-b docker-host

Setting Docker configuration on the remote daemon...
Checking connection to Docker...
Docker is up and running!

docker-machine ls 
NAME          ACTIVE   DRIVER   STATE     URL                       SWARM   DOCKER     ERRORS
docker-host   -        google   Running   tcp://34.76.129.78:2376           v18.09.2   

docker build -t reddit:latest .
Successfully built 5728f5998d5d
Successfully tagged reddit:latest

docker run --name reddit -d --network=host reddit:latest
docker tag reddit:latest sbelyanin/otus-reddit:1.0
docker push sbelyanin/otus-reddit:1.0
1.0: digest: sha256:e67067afadf2bc61fc24c365eb315e46621d835bfc7ac3bf47e50969196a59f9 size: 3034


docker run --name reddit -d --network=host reddit:latest



## Задание со *

PACKER - Создание образа уже с docker и с установленным reddit app в контейнере: docker-host-base 

cd docker-monolith/infra/packer/

packer validate -var-file variables.json  docker.json 
Template validated successfully.

packer build -var-file variables.json  docker.json
Build 'googlecompute' finished.

==> Builds finished. The artifacts of successful builds are:
--> googlecompute: A disk image was created: docker-host-1550683764



TERRAFORM - Создание инстансов на базе ubuntu-1604-lts или на базе docker-host-base 
cd ../terraform/

vim terraform.tfvars
disk_image = "docker-host-base"
node_count = 3

terraform init
terraform apply
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

docker-host_external_ip = [
    34.76.52.233,
    34.76.42.142,
    34.76.51.240
]

cd ../ansible/
ansible -m ping all
docker-host-0 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
docker-host-1 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
docker-host-2 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}

cd ../terraform/
terraform destroy
vim main.tf
disk_image = "docker-host-base"  => disk_image = "ubuntu-1604-lts"
terraform apply
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

docker-host_external_ip = [
    34.76.51.240,
    34.76.42.142,
    34.76.52.233
]

cd ../ansible/
ansible-playbook docker-install.yml 
PLAY RECAP *************************************************************************************************
docker-host-0              : ok=4    changed=3    unreachable=0    failed=0   
docker-host-1              : ok=4    changed=3    unreachable=0    failed=0   
docker-host-2              : ok=4    changed=3    unreachable=0    failed=0 

ansible-playbook docker-repull.yml
PLAY RECAP **************************************************************************************************************************************************************
docker-host-0              : ok=4    changed=3    unreachable=0    failed=0   
docker-host-1              : ok=4    changed=3    unreachable=0    failed=0   
docker-host-2              : ok=4    changed=3    unreachable=0    failed=0








 - Сравнил вывод двух следующих команд:
```bash
    >docker inspect <u_container_id>
    >docker inspect <u_image_id>
```
На основе вывода данных команд добавил в docker-monolith/docker-1.log описание в чем основное разиличие между контейнером и образом.

<details><summary>docker-monolith/docker-1.log</summary><p>

```bash
REPOSITORY                  TAG                 IMAGE ID            CREATED             SIZE
sbelyanin/ubuntu-tmp-file   latest              c3dc93a4745c        36 seconds ago      117MB
ubuntu                      16.04               7e87e2b3bf7a        3 weeks ago         117MB
hello-world                 latest              fce289e99eb9        6 weeks ago         1.84kB

Докер образ не несет в себе runtime конфигурацию, в отличии от контейнера.
Также в образе нету слоя RW для файловой ситемы, в отличии от контейнера. 

```
</p></details>
