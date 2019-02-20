[![Build Status](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices)
# sbelyanin_microservices
sbelyanin microservices repository

## HW №13

## Создание docker host
 - Создал новый проект - docker-9. Проинициализировал gcloud. 
 - Создал Service Account скачал JSON credentials в ~/gcp/infra.json. Понадобиться для ansible dynamic inventory.
 - Создал инстанс для докера при помощи docker-machine:
 
<details><summary>docker-host</summary><p>

```bash
export GOOGLE_PROJECT=docker-9

docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts --google-machine-type n1-standard-1 --google-zone europe-west1-b docker-host

Setting Docker configuration on the remote daemon...
Checking connection to Docker...
Docker is up and running!

docker-machine ls 
NAME          ACTIVE   DRIVER   STATE     URL                       SWARM   DOCKER     ERRORS
docker-host   -        google   Running   tcp://34.76.129.78:2376           v18.09.2   

```
</p></details>


## Создание своего образа
 - Создал структуру из файлов для создания имиджа.
 
 <details><summary>Dockerfile</summary><p>

```bash
FROM ubuntu:16.04
RUN apt-get update 
RUN apt-get install -y mongodb-server ruby-full ruby-dev build-essential git 
RUN gem install bundle
RUN git clone -b monolith https://github.com/express42/reddit.git

COPY mongod.conf /etc/mongod.conf
COPY db_config /reddit/db_config 
COPY start.sh /start.sh

RUN cd /reddit && bundle install 
RUN chmod 0777 /start.sh 
CMD ["/start.sh"]

```
</p></details>

- Собрал образ reddit:latest:

```bash 
eval $(docker-machine env docker-host)
docker build -t reddit:latest .
Successfully built 5728f5998d5d
Successfully tagged reddit:latest
```

- Запустил контейнер на основе созданного образа на docker-host инстансе:

```bash
docker run --name reddit -d --network=host reddit:latest
 ```
 - Разрешил на вход TCP/9292 для нашего приложения:

```bash
 gcloud compute firewall-rules create reddit-app \
    --allow tcp:9292 \
    --target-tags=docker-machine \
    --description="Allow PUMA connections" \
    --direction=INGRESS
 ```

- Проверил доступность приложения открыв его в браузере - http://{EXT-IP}:9292/
 
## Работа с Docker Hub
 - Залогинился под своим акаунтом на dockerhub через команду docker login
 - Перетегировал созданный контейнер
```bash
docker tag reddit:latest sbelyanin/otus-reddit:1.0
```
 - Загрузил созданный имидж на docker hub
 ```bash
 docker push sbelyanin/otus-reddit:1.0
1.0: digest: sha256:e67067afadf2bc61fc24c365eb315e46621d835bfc7ac3bf47e50969196a59f9 size: 3034
 ```
 - Проверил запуск и работу приложения в GCP и локально:
 ```bash
 docker run --name reddit -d -p 9292:9292 sbelyanin/otus-reddit:1.0
 ```

## Задание со *
 - Создал шаблон пакера, который делает образ с уже установленным Docker и с установленным reddit app, используя провижининг ansible: docker-host-base

<details><summary>docker.json</summary><p>

```bash
{
	"variables": {
	  "project_id": null,
	  "source_image_family": null,
	  "zone": "europe-west1-b",
	  "machine_type": "g1-small"
  	 },
	"builders": [
	  {
	   "type": "googlecompute",
	   "project_id": "{{ user `project_id` }}",
	   "image_name": "docker-host-{{timestamp}}",
	   "image_family": "docker-host-base",
	   "image_description": "for-docker-host",
	   "image_labels": {
	     "create_date": "{{timestamp}}",
	     "create_by": "sergey-belyanin",
	     "based_on": "{{ user `source_image_family` }}",
	     "add_packages": "docker"
	     },
	   "source_image_family": "{{ user `source_image_family` }}",
	   "zone": "{{ user `zone` }}",
	   "network": "default",
	   "ssh_username": "appuser",
	   "machine_type": "{{ user `machine_type` }}",
	   "disk_size": "10",
	   "disk_type": "pd-standard"
	  }
	],
	"provisioners": [
	  {
	   "type": "ansible",
	   "playbook_file": "../ansible/packer-docker.yml"
	  }
	]
}
```
</p></details>

<details><summary>packer build</summary><p>
    
```bash

cd docker-monolith/infra/packer/
packer validate -var-file variables.json  docker.json 
Template validated successfully.

packer build -var-file variables.json  docker.json
Build 'googlecompute' finished.
==> Builds finished. The artifacts of successful builds are:
--> googlecompute: A disk image was created: docker-host-1550683764

```
</p></details>

 - Создал инфраструктуру файлов Terraform для создания инстансов (определяется переменной node_count) на базе ubuntu-1604-lts или на базе docker-host-base:

<details><summary>terraform build</summary><p>
    
```bash

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
```
</p></details>

 - Настроил dynamic inventory для ansible - gce.py.
 - Создал плейбуки для установки docker и запуска контейнера sbelyanin/otus-reddit:1.0:
 
<details><summary>packer provisioner - packer-docker.yml</summary><p>
    
```bash

- hosts: all
  become: true
  tasks:
  - name: Add Docker GPG key
    apt_key: url=https://download.docker.com/linux/ubuntu/gpg

  - name: Add Docker APT repository
    apt_repository:
      repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ansible_distribution_release}} stable

  - name: Install list of packages
    apt:
      name: ['apt-transport-https','ca-certificates','curl','software-properties-common','docker-ce']
      state: present
      update_cache: yes

  - name: Pull and run reddit docker images.
command: docker run --restart always --name reddit -d -p 9292:9292 sbelyanin/otus-reddit:1.0

```
</p></details>
 

<details><summary>docker-install.yml</summary><p>
    
```bash
---
- name: Install Docker-ce
  hosts: all
  become: true
  tasks:
  - name: Add Docker GPG key
    apt_key: url=https://download.docker.com/linux/ubuntu/gpg

  - name: Add Docker APT repository
    apt_repository:
      repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ansible_distribution_release}} stable

  - name: Install list of packages
    apt:
      name: ['apt-transport-https','ca-certificates','curl','software-properties-common','docker-ce']
      state: present
update_cache: yes

```
</p></details>


<details><summary>docker-repull.yml</summary><p>
    
```bash

---
- name: Pull images and restart reddit app on Docker-ce
  hosts: all
  become: true
  tasks:
  - name: Pull reddit docker images.
    command: docker pull sbelyanin/otus-reddit:1.0

  - name: Remove found the reddit app containers
    shell: 'docker rm -f reddit'
    ignore_errors: yes

  - name: Start reddit app container
command: docker run --restart always --name reddit -d -p 9292:9292 sbelyanin/otus-reddit:1.0

```
</p></details>

 - Проверил работу ansible плейбуков по разворачиванию инфраструктуры: 

<details><summary>ansible play</summary><p>
    
```bash

## проверка работы динамического инвентори и доступности инстансов
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

#Зачистка инфраструктуры в GCP
cd ../terraform/
terraform destroy

#Выбор имиджа без предустановленного docker и количества создаваемых инстансов
vim terraform.tfvars
disk_image = "ubuntu-1604-lts"
node_count = 3

#Создание инстансов
terraform apply
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:
docker-host_external_ip = [
    34.76.51.240,
    34.76.42.142,
    34.76.52.233]

№Установка docker, получение имиджа и его запуск средствами ansible
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


```
</p></details>
