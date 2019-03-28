[![Build Status](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_microservices)
# sbelyanin_microservices
sbelyanin microservices repository

# HW №21
# Kubernetes. Запуск кластера и приложения. Модель безопасности.

 - Развернуть локальное окружение для работыс Kubernetes

<details><summary>minikube</summary><p>

```bash

kubectl get all 
NAME                           READY   STATUS    RESTARTS   AGE
pod/comment-7bc5f856f8-l6f77   1/1     Running   0          60m
pod/comment-7bc5f856f8-tdrsv   1/1     Running   0          60m
pod/comment-7bc5f856f8-tfc9v   1/1     Running   0          60m
pod/mongo-7f99599dc7-crvg2     1/1     Running   0          135m
pod/post-b4fb88ff6-j62tg       1/1     Running   0          52m
pod/post-b4fb88ff6-nv4cx       1/1     Running   0          52m
pod/post-b4fb88ff6-p975t       1/1     Running   0          52m
pod/ui-86548c47b-k47wn         1/1     Running   0          4m
pod/ui-86548c47b-k7r8s         1/1     Running   0          4m13s
pod/ui-86548c47b-sptvq         1/1     Running   0          3m54s

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/comment      ClusterIP   10.97.92.152     <none>        9292/TCP         64m
service/comment-db   ClusterIP   10.101.101.164   <none>        27017/TCP        64m
service/kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP          173m
service/mongodb      ClusterIP   10.106.138.65    <none>        27017/TCP        64m
service/post         ClusterIP   10.102.219.4     <none>        5000/TCP         64m
service/post-db      ClusterIP   10.98.115.91     <none>        27017/TCP        52m
service/ui           NodePort    10.108.184.101   <none>        9292:30176/TCP   64m

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/comment   3/3     3            3           60m
deployment.apps/mongo     1/1     1            1           135m
deployment.apps/post      3/3     3            3           64m
deployment.apps/ui        3/3     3            3           87m

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/comment-7bc5f856f8   3         3         3       60m
replicaset.apps/mongo-7f99599dc7     1         1         1       135m
replicaset.apps/post-58f5dc76d9      0         0         0       64m
replicaset.apps/post-b4fb88ff6       3         3         3       52m
replicaset.apps/ui-7464bcbfc8        0         0         0       87m
replicaset.apps/ui-86548c47b         3         3         3       4m13s
dangel@dangelpc:~/sbelyanin_microservices/kubernetes/reddit$ kubectl get all -n dev
NAME                           READY   STATUS    RESTARTS   AGE
pod/comment-7bc5f856f8-2hb2r   1/1     Running   0          7m42s
pod/comment-7bc5f856f8-dlkbl   1/1     Running   0          7m42s
pod/comment-7bc5f856f8-pmjgc   1/1     Running   0          7m42s
pod/mongo-7f99599dc7-6hjhm     1/1     Running   0          7m42s
pod/post-b4fb88ff6-6sjbh       1/1     Running   0          7m42s
pod/post-b4fb88ff6-mndzg       1/1     Running   0          7m42s
pod/post-b4fb88ff6-rrfm8       1/1     Running   0          7m42s
pod/ui-86548c47b-4vhhr         1/1     Running   0          4m15s
pod/ui-86548c47b-m2pft         1/1     Running   0          4m34s
pod/ui-86548c47b-mqhdb         1/1     Running   0          4m29s

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/comment      ClusterIP   10.109.125.15    <none>        9292/TCP         7m43s
service/comment-db   ClusterIP   10.110.14.243    <none>        27017/TCP        7m43s
service/mongodb      ClusterIP   10.98.151.196    <none>        27017/TCP        7m42s
service/post         ClusterIP   10.104.245.226   <none>        5000/TCP         7m42s
service/post-db      ClusterIP   10.100.239.72    <none>        27017/TCP        7m42s
service/ui           NodePort    10.100.201.101   <none>        9292:30707/TCP   7m42s

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/comment   3/3     3            3           7m43s
deployment.apps/mongo     1/1     1            1           7m42s
deployment.apps/post      3/3     3            3           7m42s
deployment.apps/ui        3/3     3            3           7m42s

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/comment-7bc5f856f8   3         3         3       7m42s
replicaset.apps/mongo-7f99599dc7     1         1         1       7m42s
replicaset.apps/post-b4fb88ff6       3         3         3       7m42s
replicaset.apps/ui-7464bcbfc8        0         0         0       7m42s
replicaset.apps/ui-86548c47b         3         3         3       4m34s

 
```
</p></details> 
  

 - Развернуть Kubernetes в GKE

<details><summary>k8s</summary><p>

```bash


```
</p></details>



 - Запустить reddit в Kubernetes


``` Подключение к proxy:

http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy 



<details><summary>k8s</summary><p>

```bash


```
</p></details>

## Задание со *

<details><summary>k8s</summary><p>

```bash

kubectl get clusterrolebinding kubernetes-dashboard -n kube-system -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  creationTimestamp: "2019-03-28T09:39:46Z"
  name: kubernetes-dashboard
  resourceVersion: "6599"
  selfLink: /apis/rbac.authorization.k8s.io/v1/clusterrolebindings/kubernetes-dashboard
  uid: 6c3bf6c3-513d-11e9-8d1d-42010a9a012d
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system

```
</p></details>

