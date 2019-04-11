[![Build Status](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices)
# sbelyanin_microservices
sbelyanin microservices repository

## HW №24

## Kubernetes. Мониторинг и логирование

### Prepare

 - Развернул в GKE кластер K8S при помощи Terraform с 3 нодами n1-standard-2.
 - Отключен stackdriver, устаревшие права доступа включены.
 - Установил tiller в k8s.
 - Из Helm-чарта установил ingress-контроллер nginx.

### Развертывание Prometheus в k8s 

 - Загрузил prometheus локально в Charts каталог
 - Установил в k8s prometheus с кастомными настройками (custom_values.yml)
 - Через SD к мониторингу подключены ноды, ендпоинты и сервисы.
 - При помощи relabel преобразовал лейблы таргетов в метки прометеуса.
 - Поменял метки для определения пути сбора метрик.
 - Задеплоил приложение reddit из ранее созданого чарта. В namescpace default, production и stage.
 - Настроил сбор метрик с сервисов приложения используя SD.
 - Разделил задания сборки метрик на namespace и по имени сервиса проложения.
 
### Настройка Prometheus и Grafana для сбора метрик  

 - Установил Grafana испорльзуя публичный chart, изменив параметры нужные для доступка к UI.
 - Добавил дашбоард для визуального мониторинга кластера K8S.
 - Добавил дашбоарды созданные ранее, для мониторинга сервисов приложения reddit.
 - Добавил в дашбоард переменные для удобного оторбражения метрик при динамическом изменении количества namespace`ов.
 - Добавил дашбоард одновременно использующий метрики и шаблоны из cAdvisor, и из kube-state-metrics.
 - Измененные дашбоарды сохранил в monitoring/grafana/dashboards

### Настройка EFK для сбора логов 

 - Создал манифесты в каталоге kubernetes/efk для разворачивания ES и Fluentd. Развернул их в K8S.
 - Kibana поставил из helm чарта.
 - Создал шаблон индекса на основе индекса fuentd-*
 - Просмотрел через Discover информацию о кластере K8S.
 
## Задание со *

 - Запусил и настрил alertmanager в k8s. Создал правила для мониторига доступности api-сервера и хостов k8s

<details><summary>alertmanager</summary><p>

```bash
http://10.4.1.24:9093/metrics up
app="prometheus" chart="prometheus-8.9.1" component="alertmanager" heritage="Tiller" instance="10.4.1.24:9093" kubernetes_name="prom-prometheus-alertmanager" kubernetes_namespace="default" release="prom" 

Alerts
K8S_API_Server_Down (0 active)
alert: K8S_API_Server_Down
expr: up{job="kubernetes-apiservers"}
  == 0
for: 1m
labels:
  severity: Disaster
annotations:
  description: '{{ $labels.instance }} of job {{ $labels.job }} has been down for
    more than 1 minute'
  summary: Instance {{ $labels.instance }} is down. Check Cluster Status.

K8S_Node_Down (0 active)
alert: K8S_Node_Down
expr: up{job="kubernetes-nodes"}
  == 0
for: 2m
labels:
  severity: High
annotations:
  description: '{{ $labels.instance }} of job {{ $labels.job }} has been down for
    more than 1 minute'
  summary: Instance {{ $labels.instance }} is down. Check Cluster Status.

```
</p></details> 

- Установил в кластер Prometheus Operator "helm fetch --untar stable/prometheus-operator". Манифест serviceMonitor:

<details><summary>kubernetes/Charts/prometheus-operator/post-endpoint-sm.yaml</summary><p>

```bash

apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app: my-release-prometheus-oper-post
  name: my-release-prometheus-oper-post
spec:
  endpoints:
  - port: "5000"
  selector:
    matchLabels:
      app: reddit
      component: post

```
</p></details> 

 - Создал Helm-чарт для установки стека EFK и поместил в директорию charts - "efk"
