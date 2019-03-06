[![Build Status](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices)
# sbelyanin_microservices
sbelyanin microservices repository

## HW №16

# Устройство Gitlab CI. Построение процесса непрерывной поставки

- Для разворачивания инфраструктуры выбран ansible и динамическое инвентори.
- Созданы playbooks:
```bash
docker-install.yml - инсталяция docker в систему
gitlab-install.yml - инсталяуия Gitlab в систему
host-install.yml - развертывание хоста в GCP
runner-install.yml - инсталяция и подключение раннеров
site.yml - обьеденяющий playbook
```
<details><summary>docker-install.yml</summary><p>

```bash
---
- name: Install Docker-ce Docker-compose
  hosts: all
  become: true
  vars:
    work_user: appuser
    docker_group: docker
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

  - name: Add work "appuser" user to "docker" group
    user:
      name: "{{ work_user }}"
      group: "{{ docker_group }}"
      append: yes

  - name: Install docker-compose
    apt:
      name: docker-compose=1.8.*
      state: present
      update_cache: yes

```
</p></details>

<details><summary>gitlab-install.yml</summary><p>

```bash
---
- name: Install Gitlab into docker
  hosts: all
  vars:
    work_user: appuser
    docker_group: docker
    gitlab_dir: /srv/gitlab
    gitlab_ext_ip: "{{ hostvars['docker-gitlab']['gce_public_ip'] }}"
    gitlab_runners: 1 
  tasks:

  - name: Create directory for gitlab
    become: true
    file:
      path: "{{ gitlab_dir }}"
      state: directory
      owner: "{{ work_user }}"
      group: "{{ docker_group }}"
      mode: 0770
      recurse: yes

  - name: List Docker networks 
    shell: "docker network ls"
    changed_when: False
    register: dockerNets
  - name: Create gitlab network 
    shell: "docker network create --driver bridge --subnet=172.32.200.0/24 --ip-range=172.32.200.0/24 --attachable  {{item}}"
    when: item not in dockerNets.stdout
    loop:
     - gitlab-net

  - name: Settings and copy docker-compose file
    template:
      src: template/docker-compose.yml.j2
      dest: "{{ gitlab_dir }}/docker-compose.yml"
      owner: "{{ work_user }}"
      group: "{{ docker_group }}"

  - name: run gitlab from docker-compose.yml
    docker_service:
     project_src: "{{ gitlab_dir }}"
     services: gitlab 
     restarted: yes
```
</p></details>

<details><summary>host-install.yml</summary><p>

```bash
---
# Host for Gitlab install Playbook
- name: GCE Instance for gitlab
  hosts: localhost
#INPUT YOU VARS!!!!!!
  vars:
    service_account_email: "87343312834-compute@developer.gserviceaccount.com"
    credentials_file: "~/gcp/infra.json"
    project_id: "docker-911"
    auth_kind: serviceaccount
  tasks:
    - name: Create Firewall Rule for http/s acces to gitlab
      gce_net:
        name: default
        service_account_email: "{{ service_account_email }}"
        credentials_file: "{{ credentials_file }}"
        project_id: "{{ project_id }}"
        fwname: "gitlab-firewall-rule"
        allowed: tcp:80;tcp:443;tcp:9292
        state: "present"
        target_tags: "gitlab-host"
        src_range: ['0.0.0.0/0']
    - name: create a disk
      gce_pd:
         name: 'disk-gitlab'
         disk_type: pd-standard
         size_gb: 100
         image_family: ubuntu-1604-lts
         service_account_email: "{{ service_account_email }}"
         credentials_file: "{{ credentials_file }}"
         project_id: "{{ project_id }}"
         zone: europe-west1-b
         state: present
      register: disk

    - name: Get the default SSH key
      command: cat ~/.ssh/appuser.pub
      register: ssh_key

    - name: create docker instances
      gce:
        instance_names: docker-gitlab
        zone: europe-west1-b 
        machine_type: n1-standard-1
        state: present
        service_account_email: "{{ service_account_email }}"
        credentials_file: "{{ credentials_file }}"
        project_id: "{{ project_id }}"
        disks:
           - name: disk-gitlab
             mode: READ_WRITE
        metadata : '{ 
             "startup-script" : "apt-get update",
             "sshKeys":"appuser:{{ ssh_key.stdout }}" 
          }'
        tags: "gitlab-host"
      register: gce

    - name: Save host data
      add_host:
        hostname: "{{ item.public_ip }}"
        groupname: gce_instances_ips
      with_items: "{{ gce.instance_data }}"

    - name: Wait for SSH for instances
      wait_for:
        delay: 1
        host: "{{ item.public_ip }}"
        port: 22
        state: started
        timeout: 30
with_items: "{{ gce.instance_data }}"
```
</p></details>

<details><summary>runner-install.yml</summary><p>

```bash
---
- name: Install runners and connect to gitlab
  hosts: all
  vars:
    work_user: appuser
    docker_group: docker
    gitlab_dir: /srv/gitlab
    gitlab_ext_ip: "{{ hostvars['docker-gitlab']['gce_public_ip'] }}"
    gitlab_runners: 2 
  tasks:

  - name: Get gitlab token for runner
    shell: "docker exec -ti gitlab gitlab-rails runner -e production \"puts Gitlab::CurrentSettings.current_application_settings.runners_registration_token\""
    register: gitlab_token

  - name: Show token
    debug: 
      var: gitlab_token.stdout 

  - name: Settings env
    template:
      src: template/.env.j2
      dest: "{{ gitlab_dir }}/.env"
      owner: "{{ work_user }}"
      group: "{{ docker_group }}" 

  - name: Run gitlab-runners from docker-compose.yml
    docker_service:  
     project_src: "{{ gitlab_dir }}"
     services: runner
     scale: 
       runner: "{{ gitlab_runners }}"
     restarted: yes

  - name: Get container id with runner 
    shell: "docker ps -q -f \"name=gl_runner\""
    register: "runn_id"

  - name: Show ID
    debug:
      var: runn_id.stdout

  - name: Register runners into gitlab
    shell: |
       docker exec -ti {{ item }} bash -c 'grep "docker-runner" /etc/gitlab-runner/config.toml > /dev/null || gitlab-runner register --non-interactive --registration-token "{{ gitlab_token.stdout }}" --executor "docker" --docker-image alpine:3 --docker-volumes /var/run/docker.sock:/var/run/docker.sock --docker-privileged --url "http://gitlab/" --description "docker-runner" --run-untagged --locked "false"'
with_items: "{{ runn_id.stdout_lines }}"

```
</p></details>

<details><summary>site.yml</summary><p>

```bash
---
- import_playbook: host-install.yml
- import_playbook: docker-install.yml
- import_playbook: gitlab-install.yml
#start after basic gitlab setup
#- import_playbook: runner-install.yml

```
</p></details>

- В процессе разворачивания используются шаблоны для создания .env и docker-compose.yml.
- Процесс создания ифраструктуры поделил на два этапа, первый - создание хоста, развертывание gitlab и его минимальная настройка и второй - развертывание и подключение раннеров. Все кроме первоначальной настройки происходит средствами ansible.

- Создал группу и в ней проект с содержимым репозитария sbelyanin_microservices.
- Добавил код репозитария reddit.
- Добавил тесты, окружение dev, stage и production, директива only и job для динкамического окружения.
- Итог:

<details><summary>.gitlab-ci.yml</summary><p>

```bash
image: ruby:2.4.2

stages:
  - build
  - test
  - review
  - stage
  - production

variables:
  DATABASE_URL: 'mongodb://mongo/user_posts'
#  DOCKER_HOST: tcp://docker:2375/
#  DOCKER_DRIVER: overlay2

build_job:
  stage: build
  script:
    - echo 'Building'

build_reddit:
  stage: build
  image: docker:stable
#  services:
#    - docker:dind
  script:
    - docker info
    - cd docker-monolith
    - docker build -t reddit:latest .

test_unit_job:
  stage: test   
  services:
    - mongo:latest   
  script:
    - cd reddit
    - bundle install
    - ruby simpletest.rb

test_unit_job:
  stage: test
  script:
    - echo 'Testing 1'

test_integration_job:
  stage: test
  script:
    - echo 'Testing 2'

deploy_dev_job:
  stage: review
  script:
    - echo 'Deploy'
  environment:
    name: dev
    url: http://dev.example.com


branch review:
  stage: review
  script: echo "Deploy to $CI_ENVIRONMENT_SLUG"
  environment:     
    name: branch/$CI_COMMIT_REF_NAME
    url: http://$CI_ENVIRONMENT_SLUG.example.com  
  only:
    - branches   
  except:
    - master

staging:
  stage: stage 
  when: manual
  only:     
    - /^\d+\.\d+\.\d+/
  script:     
    - echo 'Deploy'  
  environment:
    name: stage
    url: https://beta.example.com
    
production_reddit:
  stage: production
  image: docker:stable
  when: manual
  script:     
    - docker run -d --rm -p 9292:9292 reddit:latest
  environment: 
    name: production
    url: http://34.76.155.31:9292

production:
  stage: production
  when: manual
  only:
    - /^\d+\.\d+\.\d+/
  script:     
    - echo 'Deploy'  
  environment: 
    name: production
url: https://beta.example.com

```
</p></details>


# Задание со *

- В gitlab-ci.yml добавил сборку контейнера с приложением reddit:
```bash
build_reddit:
  stage: build
  image: docker:stable
  script:
    - docker info
    - cd docker-monolith
    - docker build -t reddit:latest .
```
- и его развертывание в инстансе:
```bash
production_reddit:
  stage: production
  image: docker:stable
  when: manual
  script:     
    - docker run -d --rm -p 9292:9292 reddit:latest
  environment: 
    name: production
    url: http://34.76.155.31:9292
```
- Создание контейнера сталов возможно используя имидж docker:stable, а его развертывание на самом сервере используя запуск контейнера с пробросом сокета от основного docker демона (-docker-volumes /var/run/docker.sock:/var/run/docker.sock --docker-privileged). Что не является хорошо с точки зрения безопасности. Другие варианты - используя хранилище артефактов или репозитарий докер контейнеров.

- Автоматическое развертывание раннеров и их подключение реализовал с помощью ansible и его модуля docker_service (service scale). Содержимое playbook runner-install.yml выше по тексту. В двух словах - запускаются stateless контейнеры gl_runner далее из gitlab забирается токен и сканируя все не подключенные контейнеры они подключаются как shareed runners. Поменять количество раннеров можно динамически - меняя значение gitlab_runners в runner-install.yml и запуская его. Единственнное что придется делать руками - это отстреливать "умершие" раннеры и переводя новые раннеры в определенные проекты. Так как ранеры я использовал как stateless - то в принципе можно использовать другие среды (swarm, cuber).

- Настроил интеграцию с Slack чатом, используя webhook.
