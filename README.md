[![Build Status](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices)
# sbelyanin_microservices
sbelyanin microservices repository

## HW №19

# Логирование и распределенная трассировка
# Подготовка окружения
 - Обновил код в src/ из внешнего репозитария
 - Обновил имиджи ui, comment и post
 - Создал Docker хост в GCE используя docker-machine
#  Сбор структурированных логов
 - Создал файл с описанием системы логирования:

<details><summary>docker/docker-compose-logging.yml</summary><p>

```bash
version: '3'
services:
  fluentd:
    image: ${USERNAME}/fluentd
    ports:
      - "24224:24224"
      - "24224:24224/udp"
    networks:
      back_net:
       aliases:
        - fluent

  elasticsearch:
    image: elasticsearch:6.6.2
    expose:
      - 9200
    networks:
      back_net:
       aliases:
        - elasticsearch

  kibana:
    image: kibana:6.6.2
    ports:
      - "5601:5601"
    networks:
      back_net:
       aliases:
        - kibana

  zipkin:
    image: openzipkin/zipkin
    ports:
      - "9411:9411"
    networks:
      back_net:
       aliases:
        - zipkin
      front_net:
       aliases:
        - zipkin

networks:
   back_net:
      external:
        name: back_net
   front_net:
      external:
name: front_net

```
</p></details>
 
 - Создал кастомный образ для fluentd:
 
<details><summary>logging/fluentd/Dockerfile</summary><p>

```bash
FROM fluent/fluentd:v0.12
RUN gem install fluent-plugin-elasticsearch --no-rdoc --no-ri --version 1.9.5 
RUN gem install fluent-plugin-grok-parser --no-rdoc --no-ri --version 1.0.0 
ADD fluent.conf /fluentd/etc
```
</p></details>

 - И его конфигурацию:
<details><summary>logging/fluentd/fluent.conf</summary><p>

```bash
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

<filter service.post>
  @type parser
  format json
  key_name log
</filter>

<filter service.ui>
  @type parser
  key_name log
  format grok
  grok_pattern %{RUBY_LOGGER}
</filter>

<filter service.ui>
  @type parser
  format grok
  grok_pattern service=%{WORD:service} | event=%{WORD:event} | request_id=%{GREEDYDATA:request_id} | message='%{GREEDYDATA:message}'
  key_name message
  reserve_data true
</filter>

<filter service.ui>
  @type parser
  format grok
  grok_pattern service=%{WORD:service} | event=%{WORD:event} | path=%{PATH:path} | request_id=%{GREEDYDATA:request_id} | remote_addr=%{IP:remote_addr} | method= %{WORD:method} | response_st$
  key_name message
  reserve_data true
</filter>

<match *.**>
  @type copy
  <store>
    @type elasticsearch
    host elasticsearch
    port 9200
    logstash_format true
    logstash_prefix fluentd
    logstash_dateformat %Y%m%d
    include_tag_key true
    type_name access_log
    tag_key @log_name
    flush_interval 1s
  </store>
  <store>
    @type stdout
  </store>
</match>
```
</p></details>

-  Настроил драйвер для логирования всех сервисов внутри compose-файла:

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
    environment:  
      - ZIPKIN_ENABLED=${ZIPKIN_ENABLED}
    logging:
      driver: "fluentd"     
      options:        
        fluentd-address: localhost:24224        
        tag: service.ui

  post:
    image: ${USERNAME}/post
    networks:
      back_net:
       aliases:
        - post
      front_net:
       aliases:
        - post
    environment:
      - ZIPKIN_ENABLED=${ZIPKIN_ENABLED}
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: service.post

  comment:
    image: ${USERNAME}/comment
    environment:
      - ZIPKIN_ENABLED=${ZIPKIN_ENABLED}
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

# Визуализация логов
 - Настроил индексирование логов с сервиса fluent в Kibana.
 - Посмотрел логи и опробовал различные фильры по полям в Kibana.
 - Настроил фильтр для парсинга json логов, приходящих от post сервиса, в конфиг fluentd.
# Неструктурированные логи
 - Настроил парсинг неструктурированных логов при помощи grok шаблонов для UI сервиса.
# Распределенная трасировка
 - Добавил в compose-файл для сервисов логирования сервис распределенного трейсинга Zipkin.
 - Добавил в compose-файл для сервисов приложения переменную окружения ZIPKIN_ENABLED=true (для включения в коде блоков отвечающих за передачу данных в Zipkin).
 - Просмотрел некоторые span, которые представляют собой одну операцию, которая происходит при обработке запроса.

№ Задания с * и ***
 - Настроил парсинг сообщений от сервиса UI.
 - Настроил систему распределенной трасировки Zipkin.
 - Установил имиджы приложения с "багам" внутри. В процессе трассировки было выявленно что сервис post "замораживался" на ~3 секунды при чтении поста. в ходе изучения исходников баг был обнаружен и закоментирован. После пересборки имиджей время чтения поста из базы стало приемлемым. Баг:
 
<details><summary>src/bagged/post/post_app.py</summary><p>

```bash
....
def find_post(id):
    start_time = time.time()
    max_resp_time = 3

    try:
        post = app.db.find_one({'_id': ObjectId(id)})
    except Exception as e:
        log_event('error', 'post_find',
                  "Failed to find the post. Reason: {}".format(str(e)),
                  request.values)
        abort(500)
    else:
        stop_time = time.time()  # + 0.3
        resp_time = stop_time - start_time
#        median_time = time.sleep(max_resp_time)
# This is bug^^^^^^^^^^^^^^^^^^^^^^^
        app.post_read_db_seconds.observe(resp_time)
log_event('info', 'post_find',
....

```
</p></details>

 - Во время проверки ДЗ средствами Travic CI - не проходил тест файла конфигурации fluent - fluent.conf. Символы "\\" в патерне и в тестируемом файле не сопоставляются инспектом. То что указанно в домашнем задании "\\|", заменил на "|", проверил - все работает.
 - Также для запуска эластика нужно увеличить параметр ядра на хостовой системе - "docker-machine ssh logging sudo sysctl -w vm.max_map_count=262144".
 - Также при пуле имиджей нужно точно установить версию Kibana и Elasticsearch, latest не работает.
