[![Build Status](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices)
# sbelyanin_microservices
sbelyanin microservices repository

# HW №20
# Введение в Kubernetes

## Создание примитивов
 - Создал манифесты для деплоя сервисов: post, ui, comment и mongodb в keubernetes/reddit/
 - Развернул Kubernetes кластер в GCP используя методичку "The Hard Way"

<details><summary>k8s</summary><p>

```bash

kubectl get nodes
NAME       STATUS   ROLES    AGE   VERSION
worker-0   Ready    <none>   57m   v1.12.0
worker-1   Ready    <none>   57m   v1.12.0
worker-2   Ready    <none>   57m   v1.12.0

kubectl get componentstatuses
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok                  
scheduler            Healthy   ok                  
etcd-1               Healthy   {"health":"true"}   
etcd-2               Healthy   {"health":"true"}   
etcd-0               Healthy   {"health":"true"}  

gcloud compute routes list --filter "network: kubernetes-the-hard-way"
NAME                            NETWORK                  DEST_RANGE     NEXT_HOP                  PRIORITY
default-route-334a6864837f2047  kubernetes-the-hard-way  10.240.0.0/24  kubernetes-the-hard-way   1000
default-route-3b6a0cc33b9ed5f7  kubernetes-the-hard-way  0.0.0.0/0      default-internet-gateway  1000
kubernetes-route-10-200-0-0-24  kubernetes-the-hard-way  10.200.0.0/24  10.240.0.20               1000
kubernetes-route-10-200-1-0-24  kubernetes-the-hard-way  10.200.1.0/24  10.240.0.21               1000
kubernetes-route-10-200-2-0-24  kubernetes-the-hard-way  10.200.2.0/24  10.240.0.22               1000
 
```
</p></details> 
  
  - Запустил и проверил поды из созданных манифестов

<details><summary>pods</summary><p>

```bash
NAME                                  READY   STATUS              RESTARTS   AGE     IP          NODE       NOMINATED NODE
comment-deployment-598b7f4ff8-dqttd   1/1     Running             0          14s     10.200.1.2  worker-1   <none>
mongo-deployment-6895dffdf4-4d6qh     1/1     Running             0          2m10s   10.200.0.3  worker-0   <none>
post-deployment-76fd648964-b5bdf      1/1     Running             0          2s      10.200.0.4  worker-0   <none>
ui-deployment-65bc85bcd4-ggdsp        1/1     Running             0          25s     10.200.2.2  worker-2   <none>

```
</p></details> 


## Задание со *
 - Создал плайбуки для разворачивания кластера Kubernetes в GCP - kubernetes/ansible/playbooks/*.yml
