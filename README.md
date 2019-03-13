[![Build Status](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices)
# sbelyanin_microservices
sbelyanin microservices repository

## HW №18

# Мониторинг приложения и инфраструктуры
 - Разделил файлы Docker compose на два файла, один с приложением, другой с системой мониторинга:

<details><summary>docker-compose.yml</summary><p>

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
   
volumes:
  post_db:

networks:
    front_net:
      external:
        name: front_net
    back_net:
      external:
name: back_net
```
</p></details>

<details><summary>docker-compose-monitoring.yml</summary><p>

```bash

106 lines (95 sloc) 2.05 KB
version: '3.3'

services:
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

  cadvisor:
    image: google/cadvisor:v0.29.0
    volumes:
      - '/:/rootfs:ro'
      - '/var/run:/var/run:rw'
      - '/sys:/sys:ro'
      - '/var/lib/docker/:/var/lib/docker:ro'
    ports:
      - '8080:8080'
    networks:
      back_net:
       aliases:
        - cadvisor

  grafana:
    image: grafana/grafana:5.0.0
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=Gra_fanA
    depends_on:
      - prometheus
    ports:
      - 3000:3000
    networks:
      back_net:
       aliases:
        - grafana

  alertmanager:
    image: ${USERNAME}/alertmanager
    command:
      - '--config.file=/etc/alertmanager/config.yml'
    ports:
      - 9093:9093
    networks:
      back_net:
       aliases:
        - alertmanager

volumes:
  prometheus_data:
  grafana_data:

networks:
   front_net:
      external:
        name: front_net   
   back_net:
      external:    
        name: back_net

```
</p></details>

# Мониторинг Docker контейнеров
 - Настроил сервис сбора метрик с Docker хоста при помощи cAdvisor и прописал его в цели для сборки метрик в Prometheus.
 - Проверил что метрики контейнеров собираются мониторингом.
 
# Визуализация метрик
- Добавил сервис визуализации Grafana.
- Добавил источник данных Prometheus в Grafana

# Сбор метрик работы приложения и бизнесметрик
- Добавил в систему визуализации дашбоард "Docker and system monitoring". Загрузил данный дашбоард в grafana/dashboards/DockerMonitoring.json
- Создал два дашбоарда с мониторингом сервиса и бизнес логики приложения. Поместил их в grafana/dashboards/ 	UI_Service_Monitoring.json и grafana/dashboards/Business_Logic_Monitoring.json
 
# Настройка и проверка алертинга
- Утановил и настроил дополнительный компонет для системы мониторинга Alertmanager. Настроил отправку сообщей в slack канал через web hook.
- Запушил все исполдьзуемые кастомные контейнеры на Docker hub - https://hub.docker.com/u/sbelyanin

# Задание со *
- Добавил в MakeFile билды и публикации новых сервисов.
- Добавил сбор метрик напрямую из Docker. Включил даннную опцию в докер демоне и прописал сбор метрик с него в prometheus. Использовал для визуализации готовый дашбоард - https://grafana.com/dashboards/1229. Количество метрик на порядок меньше чем в cAdvisor. Дашбоард скопировал в grafana/dashboards/docker_engine_metrics.json
- Добавил сбор метрик при помощи telegraf. Дополнительно поставил InfluxDB. Оформил все в виде отдельного docker compose файла:
<details><summary>docker-compose-telegraf.yml</summary><p>

```bash
version: '3.3'

services:
  influxdb:
    image: influxdb
    container_name: influxdb
    restart: always
    ports:
      - 8086:8086
    networks:
      back_net:
    volumes:
      - influxdb-volume:/var/lib/influxdb

  telegraf:
    image: ${USERNAME}/telegraf
    restart: always
    container_name: telegraf
    environment:
      HOST_PROC: /rootfs/proc
      HOST_SYS: /rootfs/sys
      HOST_ETC: /rootfs/etc
    hostname: myhostname
    volumes:
#      - ./telegraf/telegraf.conf:/etc/telegraf/telegraf.conf:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /sys:/rootfs/sys:ro
      - /proc:/rootfs/proc:ro
      - /etc:/rootfs/etc:ro
    networks:
      back_net:

volumes:
  influxdb-volume:

networks:  
   back_net:
      external:    
        name: back_net


```
</p></details>

- Подключил InfuxDB в Grafana. Использовал готовый дашбоард - https://grafana.com/dashboards/3056. Загрузил его в grafana/dashboards/Docker_Metrics_telegraf.json. Метрик меньше чем в cAdvisor. Но возможно я не глубоко копал. Т.к. telegraf мне показался очень большим комбайном.

- Создал алерт на превышение 6 ошибочных http запросов в минуту и добавил приемник с простым роутингом на smtp службы gmail. 
