[![Build Status](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices)
# sbelyanin_microservices
sbelyanin microservices repository

## HW №17

# Введение в мониторинг. Системы мониторинга.

# Prometheus: запуск, конфигурация, знакомство с Web UI 
 - Создал правило фаирвола в GCP для подключения к Prometheus и ReddiApp.
 - Создал инстанс для инфраструктуры используя docker-machine.
 - Запустил Prometheus в докер контейнере и подключился к нему используя Web UI.
 - Проверил что цель по умолчанию работает (сам Prometheus)
 - Переупорядочил структуру директорий.
 - Создал имидж с Prometheus и кастомным конфиг файлом.
# Мониторинг состояния микросервисов
 - Создал образы микросервисов используя docker_build.sh.
 - Изменил кастомный конфиг файл Prometheus для снятия метрик с микросервисов.
 - Подключил микросервисы в основной yml файл - docker/docker-compose.yml.
 - Запустил приложение и сервис мониторинга вместе и проверил состояние конечных точек.
 - Проверил зависимость метрики ui_health от состояния сервисов - например при отключении сервиса post, метрика ui_health и ui_health_post_availability устанавливается в ноль, а ui_health_comment_availability остается равной 1. А если отключить сервис mongodb - данные метрики устанавливаются в 0.
# Сбор метрик хоста с использованием экспортера
 - Подключил node_exporter в инфраструктуру для сбора метрик с хоста.
 - Проверил доступность конечной точки node eporter.
 - Проверил правильсть снятие метрики node_load1 используя команду "yes > /dev/null" на докер хосте.
 - Запушил все созданные имиджи на dockerhub: https://hub.docker.com/u/sbelyanin
 
Итоговый файлы:

<details><summary>docker/docker-compose.yml</summary><p>

```bash
version: '3.3'

services:
  post_db:
    image: mongo:${MONGODB_V}
    volumes:
      - post_db:/data/db
    networks:
      back_net:
       aliases:
        - post_db
        - comment_db

  ui:
    image: ${USERNAME}/ui
    hostname: reddit-app
    ports:
      - ${HOST_PORT}:9292
    networks:
      - front_net

  post:
    image: ${USERNAME}/post
    networks:
      back_net:
       aliases:
        - post
      front_net:
       aliases:
        - post

  comment:
    image: ${USERNAME}/comment
    networks:
      front_net:
        aliases:
          - comment
      back_net:
        aliases:
          - comment
   
  prometheus:
    image: ${USERNAME}/prometheus
    ports:
      - '9090:9090'
    volumes:
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention=1d'
    networks:
      front_net:
      back_net:

  node-exporter:
    image: prom/node-exporter:v0.15.2
    user: root
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.ignored-mount-points="^/(sys|proc|dev|host|etc)($$|/)"'
    networks:
      back_net:

  mongod_exporter:
    image: ${USERNAME}/mongod_exporter:${MONGOD_EXP}
    environment:
      - MONGODB_URI
    networks:
      back_net:
       aliases:
        - mongod_exporter

  blackbox_exporter:
    image: ${USERNAME}/blackbox_exporter:${BLACKBOX_EXP}
    expose:
      - "9115"
    networks:
      back_net:
       aliases:
        - blackbox
      front_net:
       aliases:   
        - blackbox

volumes:
  post_db:
  prometheus_data:

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


<details><summary>monitoring/prometheus/prometheus.yml</summary><p>

```bash
---
global:
  scrape_interval: '5s'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets:
        - 'localhost:9090'

  - job_name: 'ui'
    static_configs:
      - targets:
        - 'ui:9292'

  - job_name: 'comment'
    static_configs:
      - targets:
        - 'comment:9292'

  - job_name: 'node'    
    static_configs:
      - targets:
        - 'node-exporter:9100'

  - job_name: 'mongodb'
    static_configs:
      - targets:
        - 'mongod_exporter:9216'

  - job_name: 'blackbox'
    metrics_path: /probe
    params:
      module:   # Look for a HTTP 200 response.
        - http_2xx
        - tcp_connect
        - icmp  
    static_configs:
      - targets:
        - http://post:5000    # Target to probe post
        - http://ui:9292      # Target to probe ui
        - http://comment:9292 # Target to probe comment
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
replacement: blackbox:9115  # The blackbox exporter's real hostname:port.

```
</p></details>

# Задания со *
 - Добавил Prometheus мониторинг MongoDB, использовал https://github.com/percona/mongodb_exporter . Создал monitoring/mongod_exporter/Dockerfile:
 ```bash
FROM golang:1.11
WORKDIR /go/src/github.com/percona/mongodb_exporter
RUN git clone "https://github.com/percona/mongodb_exporter" /go/src/github.com/percona/mongodb_exporter
RUN make build
FROM quay.io/prometheus/busybox:latest
COPY --from=0 /go/src/github.com/percona/mongodb_exporter/bin/mongodb_exporter /bin/mongodb_exporter
EXPOSE 9216
ENTRYPOINT [ "/bin/mongodb_exporter" ]
```
 - Добавил Prometheus мониторинг сервисов comment, post, ui с помощью blackbox экспортера - monitoring/blackbox_exporter/Dockerfile:
 ```bash
FROM prom/blackbox-exporter:v0.14.0
COPY config.yml /etc/blackbox_exporter/config.yml
```
 - Создал файл Makefile для билда всех, билда по одному и пуша всех использованных имиджей в ДЗ:

<details><summary>Makefile</summary><p>

```bash
export USERNAME=sbelyanin
export MONGOD_EXP=v0.6.3 
export BLACKBOX_EXP=v0.14.0
export COMPOSE_TLS_VERSION=TLSv1_2


build-all:
	docker build -t $(USERNAME)/prometheus monitoring/prometheus/
	docker build -t $(USERNAME)/comment src/comment/
	docker build -t $(USERNAME)/post src/post-py/
	docker build -t $(USERNAME)/ui src/ui/
	docker build -t $(USERNAME)/blackbox_exporter:$(BLACKBOX_EXP) monitoring/blackbox_exporter/
	docker build -t $(USERNAME)/mongod_exporter:$(MONGOD_EXP) monitoring/mongod_exporter/
#
build-ui:
	docker build -t $(USERNAME)/ui src/ui/
build-comment:
	docker build -t $(USERNAME)/comment src/comment/
build-post:
	docker build -t $(USERNAME)/post src/post-py/
build-prometheus:
	docker build -t $(USERNAME)/prometheus monitoring/prometheus/
build-blackbox-exp:
	docker build -t $(USERNAME)/blackbox_exporter:$(BLACKBOX_EXP) monitoring/blackbox_exporter/
build-mongod-exp:
	docker build -t $(USERNAME)/mongod_exporter:$(MONGOD_EXP) monitoring/mongod_exporter/

push-all:
	docker push $(USERNAME)/prometheus
	docker push $(USERNAME)/comment
	docker push $(USERNAME)/post
	docker push $(USERNAME)/ui
	docker push $(USERNAME)/blackbox_exporter:$(BLACKBOX_EXP)
docker push $(USERNAME)/mongod_exporter:$(MONGOD_EXP)

```
</p></details>
