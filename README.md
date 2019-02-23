[![Build Status](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices)
# sbelyanin_microservices
sbelyanin microservices repository

## HW №14

# Новая структура приложения
 - Разбил приложение на 4 сервиса
 ```bash
 post-py - сервис отвечающий за написание постов
 comment - сервис отвечающий за написание комментариев
 ui - веб-интерфейс, работающий с другими сервисам
 mongodb - БД приложения
 ```
 - Созданы 3 докер файла, описывающие создание сервисов:
 
 <details><summary>Dockerfile for post-py</summary><p>

```bash
FROM python:3.6.0-alpine

WORKDIR /app
ADD . /app

RUN apk update && apk --no-cache add gcc musl-dev
RUN pip install --upgrade pip && pip install -r /app/requirements.txt

ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts

ENTRYPOINT ["python3", "post_app.py"]

```
</p></details>

 <details><summary>Dockerfile for comment</summary><p>

```bash
FROM ruby:2.2
RUN apt-get update -qq && apt-get install -y build-essential

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME

ENV COMMENT_DATABASE_HOST comment_db
ENV COMMENT_DATABASE comments

CMD ["puma"

```
</p></details>

 <details><summary>Dockerfile for ui</summary><p>

```bash
FROM ubuntu:16.04
RUN apt-get update \
    && apt-get install -y --force-yes --no-install-recommends ruby-full ruby-dev build-essential \
    && gem install bundler --no-ri --no-rdoc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
```
</p></details>

- Для БД (mongodb) контейнер специально не создавался - использовался официальный с docker hub.
- Создал кастомную сеть и волум для приложения:
```bash
docker network create reddit
docker volume create reddit_db
```
- Проверил сборку и запуск приложения:
```bash
Билд:
docker pull mongo:latest
docker build -t sbelyanin/post:1.0 ./post-py
docker build -t sbelyanin/comment:1.0 ./comment
docker build -t sbelyanin/ui:2.0 ./ui

Запуск:
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db  mongo:latest
docker run -d --network=reddit --network-alias=p- ost sbelyanin/post:1.0
docker run -d --network=reddit --network-alias=comment sbelyanin/comment:1.0
docker run -d --network=reddit -p 9292:9292 sbelyanin/ui:2.0
```
- На этапе сборки видно что некоторые шаги  сборки докер кэширует и сборка происходит быстрее. Иногда это может приводить к нежелательным последствиям. Отключается данная фича параметром --no-cache при создании имиджа.
- Проверил работоспособность приложения подключаясь к http://{EXT-IP-DOCKER-HOST}:9292 вводя новые посты и проверяя после перезаруска приложения (волум бд вынесен в хост систему - -v reddit_db:/data/db). 
 
# Задание со *

 - Запустил контейнеры с другими сетевыми алиасами и выставил переменные окружение в соотвествии с сетевыми алиасами:
 ```bash
 
docker run -d --network=reddit --network-alias=db_mongo -v reddit_db:/data/db  mongo:latest
docker run -d --network=reddit --network-alias=post_app -e POST_DATABASE_HOST=db_mongo sbelyanin/post:1.0
docker run -d --network=reddit --network-alias=comment_app -e COMMENT_DATABASE_HOST=db_mongo sbelyanin/comment:1.0
docker run -d --network=reddit --hostname=app.ui -p 9292:9292 -e POST_SERVICE_HOST=post_app -e COMMENT_SERVICE_HOST=comment_app sbelyanin/ui:2.0
 
 ```
 - Проверил работоспособность приложения подключаясь к http://{EXT-IP-DOCKER-HOST}:9292 вводя новые посты и проверяя после перезаруска приложения.
 - Оптимизировал образы приложения используя за основу образ alpine, мултистайдж сборку и удаляя ненужные кэши и пакеты системы.  
 - Размер имиджей до оптимизации: 

 <details><summary>Docker images</summary><p>

```bash

docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
sbelyanin/ui        2.0                 a186bb620e15        36 minutes ago      456MB
sbelyanin/comment   1.0                 1156169f42fc        37 minutes ago      776MB
sbelyanin/post      1.0                 5266c4c29e16        39 minutes ago      206MB

```
</p></details>

 - Размер имиджей после оптимизации:

 <details><summary>New Docker images</summary><p>

```bash

docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
sbelyanin/ui        2.1                 bf0c02cf533e        4 seconds ago       153MB
sbelyanin/comment   2.0                 2b325afcc469        17 seconds ago      151MB
sbelyanin/post      2.0                 faa3badefd48        2 hours ago         99.4MB

```
</p></details>

- Докер файлы:

 <details><summary>Dockerfile.1 for post-py</summary><p>

```bash
FROM python:3.6.0-alpine as base
FROM BASE as builder

RUN apk --no-cache add gcc musl-dev

WORKDIR /install
COPY requirements.txt /requirements.txt
RUN pip install --upgrade pip && pip install --install-option="--prefix=/install" -r /requirements.txt


FROM base

COPY --from=builder /install /usr/local

WORKDIR /app
ADD . /app


ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts

ENTRYPOINT ["python3", "post_app.py"]

```
</p></details>



 <details><summary>Dockerfile.1 for comment</summary><p>

```bash

FROM ruby:2.2-alpine


ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
ADD . $APP_HOME

RUN apk add --virtual .build --no-cache  build-base libffi-dev \
        && bundle install \
        && apk del .build


ENV COMMENT_DATABASE_HOST comment_db
ENV COMMENT_DATABASE comments


CMD ["puma"]

```
</p></details>



 <details><summary>Dockerfile.1 for ui</summary><p>

```bash
FROM ruby:2.2-alpine


ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
ADD . $APP_HOME

RUN apk add --virtual .build --no-cache  build-base libffi-dev \
        && bundle install \
        && apk del .build


ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]



```
</p></details>




