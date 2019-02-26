[![Build Status](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices)
# sbelyanin_microservices
sbelyanin microservices repository

## HW №15

# Docker: сети, docker-compose

# Работа с сетями в Docker
 - Запустил контейнер с драйвером сети none, в контейнере присуствует только loopback интерфейс

<details><summary>network none</summary><p>

```bash

docker run -ti --rm --network none joffotron/docker-net-tools -c ifconfig
 
 lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

```
</p></details>

 - Запустил контейнер с драйвером сети host, в контейнере присуствуют все интерфейсы хостовой системы.
 - Убедился что в хостовой системе и в контейнере в случае использования драйвера host сетевое окружение одинаково:
 ```bash
docker run -ti --rm --network host joffotron/docker-net-tools -c ifconfig           
docker-machine ssh docker-host ifconfig 
 ```
 - Убедился что при использовании host контейнеры и хост ситема не могут исполльзовать один сетевой порт между собой:
 
<details><summary>network host</summary><p>

```bash

docker run --network host -d nginx 
docker run --network host -d nginx 
docker run --network host -d nginx 
docker run --network host -d nginx 

docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                      PORTS               NAMES
2b0087522661        nginx               "nginx -g 'daemon of…"   22 seconds ago      Exited (1) 18 seconds ago                       ecstatic_yonath
81811fe62369        nginx               "nginx -g 'daemon of…"   24 seconds ago      Exited (1) 20 seconds ago                       musing_goldberg
121e655e0ddb        nginx               "nginx -g 'daemon of…"   26 seconds ago      Exited (1) 22 seconds ago                       musing_raman
c61730866298        nginx               "nginx -g 'daemon of…"   31 seconds ago      Up 28 seconds                                   festive_minsky

docker logs ecstatic_yonath
2019/02/24 18:00:33 [emerg] 1#1: bind() to 0.0.0.0:80 failed (98: Address already in use)
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
2019/02/24 18:00:33 [emerg] 1#1: bind() to 0.0.0.0:80 failed (98: Address already in use)
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
2019/02/24 18:00:33 [emerg] 1#1: bind() to 0.0.0.0:80 failed (98: Address already in use)
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
2019/02/24 18:00:33 [emerg] 1#1: bind() to 0.0.0.0:80 failed (98: Address already in use)
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
2019/02/24 18:00:33 [emerg] 1#1: bind() to 0.0.0.0:80 failed (98: Address already in use)
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
2019/02/24 18:00:33 [emerg] 1#1: still could not bind()
nginx: [emerg] still could not bind()

```
</p></details>
 
 - Повторил запуски контейнеров с использованием драйверов none и host - добавляются net-namespaces в случае их создания докером

<details><summary>net-namespaces</summary><p>

```bash 

docker-machine ssh docker-host
sudo ln -s /var/run/docker/netns /var/run/netns 
sudo ip netns
3bbe8528a414  # none driver
default  #host driver

```
</p></details>
 
 - Разделил сетевую инфраструктура на две bridge сети - back_net и front_net. Для связи между хостами испольовал встроенный DNS docker.

<details><summary>more bridge net</summary><p>

```bash 

docker network create reddit
docker network create back_net --subnet=10.0.2.0/24
docker network create front_net --subnet=10.0.1.0/24

docker volume create reddit_db

docker kill $(docker ps -q)
docker run -d --network=back_net --name mongo_db --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db  mongo:latest
docker run -d --network=back_net --name post sbelyanin/post:1.0
docker run -d --network=back_net --name comment sbelyanin/comment:1.0
docker run -d --network=front_net --name ui -p 9292:9292 sbelyanin/ui:2.0

```
</p></details>

 - Добавил недостающюю связанность между сервисами 
```bash
docker network connect front_net post
docker network connect front_net comment 
```
 - Изучил сетевой стек хостовой системы после проделанных манипуляций:

<details><summary>soft bridge</summary><p>

```bash 
sudo docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
7c07f417ca20        back_net            bridge              local
2ee12be3e34b        bridge              bridge              local
ee072551feed        front_net           bridge              local
12db5a55cf9e        host                host                local
4a5730e5dbd9        none                null                local
f63a0fedce0b        reddit              bridge              local

ifconfig | grep br 
br-7c07f417ca20 Link encap:Ethernet  HWaddr 02:42:49:76:51:c8  # back_net
br-ee072551feed Link encap:Ethernet  HWaddr 02:42:f3:a7:ff:c3  # fron_net
br-f63a0fedce0b Link encap:Ethernet  HWaddr 02:42:ab:f3:b5:72  # старый

brctl show br-7c07f417ca20
bridge name     bridge id               STP enabled     interfaces
br-7c07f417ca20         8000.0242497651c8       no      veth4583853
                                                        veth539ccc7
                                                        vethc930d9b 
```
</p></details>

 - Посмотрел как выглядит фаирвал на базе iptables после докер манипуяций

<details><summary>iptables</summary><p>

```bash 

sudo iptables -nL -t nat
Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination         
MASQUERADE  all  --  10.0.1.0/24          0.0.0.0/0           
MASQUERADE  all  --  10.0.2.0/24          0.0.0.0/0           
MASQUERADE  all  --  172.18.0.0/16        0.0.0.0/0           
MASQUERADE  all  --  172.17.0.0/16        0.0.0.0/0           
MASQUERADE  tcp  --  10.0.1.2             10.0.1.2             tcp dpt:9292

ps ax | grep docker-proxy
 4271 pts/0    S+     0:00 grep --color=auto docker-proxy
31735 ?        Sl     0:00 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 9292 -container-ip 10.0.1.2 -container-port 9292

```
</p></details>

# Использование docker-compose
 - Создал docker-compose.yml в src
 - Добавил использование наскольких сетей для разделение бэк и фронт енда
 - Параметризировал версии сервисов, порт фронт сервиса и имя маинтейнера имиджей при помощи файла .env
 - Выяснил что базовое имя имя образуется от имени текущей директории, строки "container_name", праметра "-p" и переменной "COMPOSE_PROJECT_NAME". Также следует учитывать что в случае запуска приложения как сервиса - данные параметры могут игнорироваться или быть несовместимыми.
 
<details><summary>.env.example</summary><p>

```bash 

USERNAME=sbelyanin

MONGODB_V=3.2

POST_V=1.0

COMMENT_V=1.0

HOST_PORT=9292
UI_V=1.0

```
</p></details>


<details><summary>docker-compose.yml</summary><p>

```bash 

version: '3.3'

services:
  mongo_db:
    image: mongo:${MONGODB_V}
    volumes:
      - mongo_db:/data/db
    networks:
      back_net:
       aliases:
        - post_db
        - comment_db

  ui:
    build: ./ui
    image: ${USERNAME}/ui:${UI_V}
    hostname: reddit-app
    ports:
      - ${HOST_PORT}:9292
    networks:
      - front_net

  post:
    build: ./post-py
    image: ${USERNAME}/post:${POST_V}
    networks:
      back_net:
       aliases:
        - post
      front_net:
       aliases:
        - post

  comment:
    build: ./comment
    image: ${USERNAME}/comment:${COMMENT_V}
    networks:
      front_net:
        aliases:
          - comment
      back_net:
        aliases:
          - comment

volumes:
  mongo_db:

networks:
  front_net:
    ipam:
      config:
        - subnet: 10.0.3.0/24
  back_net:
    ipam:
      config:
- subnet: 10.0.4.0/24
 

```
</p></details>

 - ИТОГ:
```bash 
export COMPOSE_TLS_VERSION=TLSv1_2
docker-compose up -d
docker ps
CONTAINER ID        IMAGE                   COMMAND                  CREATED             STATUS              PORTS                    NAMES
9af56f4efa4b        mongo:3.2               "docker-entrypoint.s…"   11 seconds ago      Up 9 seconds        27017/tcp                src_mongo_db_1
efcd66002468        sbelyanin/comment:1.0   "puma"                   11 seconds ago      Up 7 seconds                                 src_comment_1
5f2e4e93ac46        sbelyanin/post:1.0      "python3 post_app.py"    11 seconds ago      Up 8 seconds                                 src_post_1
6277d6e8a49a        sbelyanin/ui:1.0        "puma"                   11 seconds ago      Up 9 seconds        0.0.0.0:9292->9292/tcp   src_ui_1
```


# Задание со *
 - Добавил внешние волумы для хранения кода вне контейнера.
 - Изменил параметры запуска ruby приложений через entrypoin.

<details><summary>docker-compose.override.yml</summary><p>

```bash 
version: '3.3'

services:
  post:
   volumes:
     - /srv/reddit/post-py/:/app/:rw

  ui:
   entrypoint:
     - puma
     - -w 2
     - --debug
   volumes:
      - /srv/reddit/ui/:/app/:rw

  comment:
   entrypoint:
     - puma
     - w 2
     - --debug
   volumes:
- /srv/reddit/comment/:/app/:rw


```
</p></details>
