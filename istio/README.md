# Resumo sobre istio

O Istio é uma malha de serviço de código aberto que ajuda as organizações a executar apps distribuídos baseados em microsserviços em qualquer lugar. Por que usar o Istio? Com o Istio, as organizações podem proteger, conectar e monitorar microsserviços para modernizar os apps empresariais com mais rapidez e segurança.]


### Arquiterura resumida

As configurações do istio estão no istioD, que é um daemon com as definições de segurança, tráfego, resiliência, ou qualquer outra coisa definida. Chamamos o istioD de control plane. A cada pod que contenha definição do istio, haverá também um proxy do istio com as definições para aquele pod. Isso demonstra que a comunicação inicial entre pods na verdade sempre será a princípio entre proxies istio, e isso de cara demonstra como é fácil para o istio conter métricas de aplicação. Essa comunicação entre pods se chama Data plane.


Para praticar um pouco em nosso ambiente local, iremos instalar um cluster de kubernetes local, o [k3d](https://k3d.io/). Segue abaixo o comando para instalação no linux:

```
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

```

Agora vamos criar o cluster no k3d, fazendo binding da nossa posta 8000 para a porta nodeport do kubernetes (30000)

```
k3d cluster create -p "8000:30000@loadbalancer" --agents 2
```

Após executado, vamos mudar o contexto do kubernetes para nosso novo cluster:

```
fabio@DESKTOP-345:~/fullcycle/kubernetes/k8s/namespaces$ kubectl config use-context k3d-k3s-default
Switched to context "k3d-k3s-default".
```


Agora podemos ver todos os nodes criados pelo nosso comando (2), bem como o node correspondente ao control plane.

```
fabio@DESKTOP-67:~/fullcycle/kubernetes/k8s/namespaces$ kubectl get nodes
NAME                       STATUS   ROLES                  AGE     VERSION
k3d-k3s-default-server-0   Ready    control-plane,master   4m2s    v1.28.8+k3s1
k3d-k3s-default-agent-1    Ready    <none>                 3m57s   v1.28.8+k3s1
k3d-k3s-default-agent-0    Ready    <none>                 3m57s   v1.28.8+k3s1
```

#### Instalando o istioctl

No [site do istio](https://istio.io/latest/docs/setup/getting-started/#download) temos o passo a passo de como instalar e configurar o istioctl no nosso terminal. Basicamente faremos os seguintes comandos:

```
curl -L https://istio.io/downloadIstio | sh -
```

Isso baixará o istio na nossa máquina. Moverei a pasta baixada para o /opt, e irei expor o bin dessa pasta na variável path:

```
sudo mv /home/fabiobione/fullcycle/istio-1.21.2/ /opt/
...
export PATH="$PATH:/opt/istio-1.21.2/bin"
```

Após isso, o comando istioctl deve ser reconhecido pelo terminal.


#### Instalando o istio no nosso cluster.

Iremos instalar o profile default do istio, que trata do istioD e do gateway de ingress.


```
fabio@DESKTOP-345:/opt/istio-1.21.2$ istioctl install
This will install the Istio 1.21.2 "default" profile (with components: Istio core, Istiod, and Ingress gateways) into the cluster. Proceed? (y/N) y
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ Installation complete
Made this installation the default for injection and validation.
```

Agora vamos verificar alguns componentes criados pelo istio:

```
fabio@DESKTOP-345:/opt/istio-1.21.2$ kubectl get ns
NAME              STATUS   AGE
kube-system       Active   32m
kube-public       Active   32m
kube-node-lease   Active   32m
default           Active   32m
istio-system      Active   3m16s
fabio@DESKTOP-345:/opt/istio-1.21.2$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istiod-5668557955-t2t85                 1/1     Running   0          3m39s
istio-ingressgateway-84cd7548bb-bsjcj   1/1     Running   0          2m41s
fabio@DESKTOP-345:/opt/istio-1.21.2$ kubectl get services -n istio-system
NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)
          AGE
istiod                 ClusterIP      10.43.5.32     <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP        4m12s
istio-ingressgateway   LoadBalancer   10.43.252.25   <pending>     15021:30993/TCP,80:31587/TCP,443:31874/TCP   3m14s
```

Podemos ver a criação do namespace istio-system. Nesse namespace foram criados pods para istiod e ingress. No service, temos o loadbalancer do gateway de ingress.


### Inserindo sidecar em um container

Sidecar é o proxy criado pelo istio que ficará na frente dos conteineres. E para habilitar o proxy, podemos executar o seguinte comando: 

```
kubectl label namespace default istio-injection=enabled
```

Esse comando libera a injeção feita pelo istio no namespace default. Agora podemos executar um deployment no namespace default, e o seu container já terá 2 pods, no nosso caso o do istio (sidecar proxy) e o do nginx, como determinado pelo deployment.yml abaixo:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 80

```

Ao aplicar o deployment, podemos reparar a criação de 2 pods no container do nginx:

```
kubectl apply -f deployment.yml
. . . 
fabio@DESKTOP-234:~/fullcycle/istio$ kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
nginx-57f79d6686-kzsvk   2/2     Running   0          5m27s

```