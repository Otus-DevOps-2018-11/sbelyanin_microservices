# sbelyanin_microservices
sbelyanin microservices repository

## HW №12

- Установил docker, docker-compose и docker-machine
- Запустил docker hello-world
- Запустил образ ubuntu:16.04 в двух контейнерах (без удаления при остановке) с выполнением /bin/bash. В одном из контейнеров создал файл /tmp/file с строкой "Hello world!"
- Нашел (docker ps -a) остановленный контейнер, запустил его (docker start) и подключился к нему (docker attach).
- Проверил что это нужный контейнер и файл на месте - cat /etc/file
- Создал образ из найденного и запущенного контейнера - docker commit {CID} sbelyanin/ubuntu-tmp-file
- Список локальных образов сохранил - docker images > docker-monolith/docker-1.log

## Задание со *

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
