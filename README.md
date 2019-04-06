[![Build Status](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices)
# sbelyanin_microservices
sbelyanin microservices repository

## HW №23

## CI/CD в Kubernetes. Интеграция Kubernetes в GitlabCI.

### Работа с Helm.

 - Развернул в GKE кластер K8S при помощи Terraform.
 - Установил helm (локально, позже пришлось понижать версию) и tiller в k8s.
 - Создал директорию Charts со структурой необходимой для создания чартов приложения reddit (файлы описания чартов и шаблонизиррованые манифесты).
 - Кастомизировал манифесты своими переменными.
 - Развернул в kubernetes кластере приложение reddit через helm charts.

### Развертывание Gitlab в Kubernetes 

 - Развернул в кластере Kubernetes Gitlab (omnibus) , используя кастомный чарт.

### Запуск CI/CD конвейера в Kubernetes 

 - Создал пайпланы для развертывания в stage и prod окружения микросервисов приложения reddit.
 - Проверил что review работает и зачищается в кластере после просмотра.
 
## Задание со *
## Использование Gitlab Pipeline triggers API

 - Используя Gitlab Pipeline triggers API связал пайплайны микросервисов (ref=master) с пайплайном деплоя приложения в прод среду.
