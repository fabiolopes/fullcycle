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


### Addons importantes para incrementar

Na página do [istio getting started](https://istio.io/latest/docs/setup/getting-started/#dashboard) temos o [github de samples](https://github.com/istio/istio/tree/release-1.21/samples/addons). Vamos instalar as seguintes ferramentas:

* grafana - Plataforma visual de métricas de 
aplicações;
* jaeger - É um mecanismo para rastreamento de requisições de uma requisição/serviço;
* kiali - Interface gráfina para observabilidade de serviços de rede;

Vamos executar na ordem de funcionamento, usando o raw dos arquivos hospedados no github:


```
#prometheus
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/addons/prometheus.yaml
. . . 
#kiali
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/addons/kiali.yaml
. . . 
#jaeger
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/addons/jaeger.yaml
. . .
#grafana
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/addons/grafana.yaml
```

Olhando o conteúdo desses deployments podemos observar que estão sendo aplicados no namespace istio-system. Vamos dar uma olhada nmos pods criados nesse namespace:

```
fabio@DESKTOP-345:~/fullcycle/istio$ kubectl get pods -n istio-system
NAME                                    READY   STATUS              RESTARTS   AGE
istiod-5668557955-t2t85                 1/1     Running             0          3d22h
istio-ingressgateway-84cd7548bb-bsjcj   1/1     Running             0          3d22h
prometheus-7545dd48db-rftbh             0/2     ContainerCreating   0          6m23s
jaeger-7d7d59b9d-lw65w                  0/1     ContainerCreating   0          3m40s
grafana-6f68dfd8f4-jzm56                0/1     ContainerCreating   0          2m27s
kiali-588bc98cd-b2cnl                   1/1     Running             0          5m31s
```

#### Vendo o dashboard do kiali

Executamos o seguinte comando:

```
fabio@DESKTOP-45:~/fullcycle/istio$ istioctl dashboard kiali
http://localhost:20001/kiali
```

Se o browser não abrir automaticamente, podemos acessar a url http://localhost:20001/kiali no browser. Vamos ver como é a página inicial:

![kiali](./imgs/kiali-pg-inicial.png)

Vamos dar também uma olhada na aba Graphs, onde ao selecionar o namespace default e permitir display "idles nodes" conseguiremos ver o node de kubernetes e nginx.

![kiali-nodes](./imgs/kiali-idle-nodes.png)

### Reforçando conceitos do istio

* __Ingress gateway__ - Controlador de entrada de requisições em um serviço

* __Virtual service__ - Camada virtual complementar ao service do kubernetes que permite configurações de roteamento de um serviço

* __Destination rules__ - Set de regras para configurar o que acontece com o tráfego quando chega em determinado destino.

Agora, para pôr a mão na massa, vamos criar um arquivo deployment do nginx, 1 com nome nginx, e a imagem wesleywillians/nginx-ab, outro com nome nginx-b, e a imagem wesleywillians/nginx-ab:b. Ambos atendem pela label nginx. Criaremos também um service para acessar os apps da label nginx, e vamos ver o comportamento das requisições:

deployment.yml:
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
        image: wesleywillians/nginx-ab
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 80

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-b
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
        image: wesleywillians/nginx-ab:b
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 80

---

apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 8000
    targetPort: 80
    nodePort: 30000

```

Aplicaremos o arquivo:

```
fabio@DESKTOP-343:~/fullcycle/istio$ kubectl apply -f .
deployment.apps/nginx unchanged
deployment.apps/nginx-b created
service/nginx-service created
```

Agora vamos fazer algumas requisições na url da aplicação e ver como serão as chamadas:

```
fabio@DESKTOP-455:~/fullcycle/istio$ while true;do curl http://localhost:8000; echo; sleep 0.
5; done;
Full Cycle B
Full Cycle B
Full Cycle B
Full Cycle A
Full Cycle A
Full Cycle B
Full Cycle B
Full Cycle B
Full Cycle A
Full Cycle B
Full Cycle A
Full Cycle B
```


Vamos modificar o arquivo deployment. Adicionando no primeiro a version A, e no segundo a version B para diferenciar.

```
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
        version: A
. . . 

spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
        version: B
```


Agora comando de apply:
```
fabio@DESKTOP-343:~/fullcycle/istio$ kubectl apply -f .
```

E vamos executar o script while, e o comando de dashboard para ver a diferenciação de tráfego.

```
while true;do curl http://localhost:8000; echo; sleep 0.5; done;
. . .

fabio@DESKTOP-544:~$ istioctl dashboard kiali
http://localhost:20001/kiali
```

Agora acessando o Graph do dashboard, veremos o seguinte:

![istio A e B](./imgs/kiali-istio-a-b.png)


### Deploy canário

Deploy canário é uma estratégia de atualização de versão suavizada, a fim de consolidar a mudança aos poucos. 

Pensando em executar isso usando kubernetes, imagine uma aplicação que já esteja na versão 1.0 em produção. Essa aplicação poderia ter 10 réplicas. Ao subir a nova versão 1.1, podemos manter a versão 1.0 com 8 réplicas, e a 1.1. terá 2 réplicas. De forma automática, o load balancer irá jogar em média 80% das requisições para os pods de 1.0, e 20% da 1.1. Você terá um grupo menorde requisições provando da nova implementação e em exposição a possíveis falhas. Mas a maioria dos usuário não terão impacto. Conforme for validando a nova implementação 1.1., podemos subtrair pods da 1.0, adicionando na 1.1. Até a 1.1 obter todos os 10 pods.

Para fazer isso, poderíamos alterar no deployment o campo réplicas.

Se formos aplicar a lógica de distribuição de requisições com istio, tendo cada deploy 1 réplica, temos a seguinte forma:

Em Graph, no lado direito, selecionamos o menu de contexto e Details do service.
![istio-service](./imgs/istio-service-details.png)

Em Actions, selecionamos Traffic shifting
![istio-traffic](./imgs/istio-traffic-shifting.png)

Agora selecionamos o peso da disteribuição de tráfego.
![istio-sifting-aplicado](./imgs/istio-traffic-shifting-aplicado.png)


#### Executando carga de requisições com o Fortio

Na documentação do istio, temos a descrição de instalação do Fortio para testarmos o tráfego, na seção [circuit-breaking](https://istio.io/latest/docs/tasks/traffic-management/circuit-breaking/). Nela temos os comando de criação do container do Fortio:

```
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/httpbin/sample-client/fortio-deploy.yaml
. . . 
export FORTIO_POD=$(kubectl get pods -l app=fortio -o 'jsonpath={.items[0].metadata.name}')
```

Agora vamos rodar requisições do fortio por 200 segundos:

```
kubectl exec "$FORTIO_POD" -c fortio -- fortio load -c 2 -qps 0 -t 200s -loglevel Warning http://nginx-service:8000
```

Vamos rodar também o kiali para ver os detalhes:

```
fabio@DESKTOP-2134:~$ istioctl dashboard kiali
http://localhost:20001/kiali
Failed to open browser; open http://localhost:20001/kiali in your browser.
```

Agora vamos mudar as configurações de tráfego novamente no traffic shifting:

![10_90](./imgs/kiali-10_90.png)

O resultado é que as requisições vão se distribuir naturalmente conforme configuramos:

![graph_10_90](./imgs/kiali-graph_90_10.png)


### Configurando um virtual service e destination rule para controle de carga via yml

No passo anterior executamos configuração manual no kiali para definir a carga. Por baixo dos panos são criados arquivos yml. Vamos criar esses arquivos para serem gerados via kubectl.

Primeiro iremos configurar um arquivo de __DestinationRule__.

```
#ds.yml

apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: nginx-dr
spec:
  host: nginx-service
  subsets:
    - name: v1
      labels:
        version: A
    - name: v2
      labels:
        version: B
```

Configuramos a ruleset v1 para a versão A, e a v2 para a version B. Agora definiremos o VirtualService, que irá utilizar essas destinações com carga definida:

```
#vs.yml

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: nginx-vs
spec:
  hosts:
  - nginx-service
  http:
    - route:
      - destination:
          host: nginx-service
          subset: v1
        weight: 90
      - destination:
          host: nginx-service
          subset: v2
        weight: 10
```

Nesse caso, configuramos para o subset v1, peso 90, e peso 10 para o subset v2. Agora daremos apply em todos os arquivos criados:

```
fabio@DESKTOP-23424:~/fullcycle/istio$ kubectl apply -f .
deployment.apps/nginx unchanged
deployment.apps/nginx-b unchanged
service/nginx-service unchanged
destinationrule.networking.istio.io/nginx-dr created
virtualservice.networking.istio.io/nginx-vs created
```

Iremo agora rodar o kiali dashboar, bem como executaremos o teste de carga com o fortio, isso em terminais diferentes, visto que esses comandos travam o terminal:

```
kubectl exec "$FORTIO_POD" -c fortio -- fortio load -c 2 -qps 0 -t 200s -loglevel Warning http://nginx-service:8000

istioctl dashboard kiali
```

Se tudo der certo, a distribuição no Graph do kiali mostrará a divisão de tráfego aproximada de 90/10.


### Configurando algoritmos de load balancer

Por padrão, o algoritmo utilizado para fazer o balanceamento é round robin, mas temos outros, como least connection, random. Vamos configurar o destination rule com essa definição:

```
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: nginx-dr
spec:
  host: nginx-service
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
  subsets:
    - name: v1
      labels:
        version: A
      trafficPolicy:
        loadBalancer:
          simple: LEAST_CONN
    - name: v2
      labels:
        version: B
```

Ao aplicar o arquivo, levando em consideração que haja mais réplicas por deployment, o algoritmo selecionado irá atuar no balanceamento de carga.

### Entendendo stick session e consistent hash

No nosso cenário atual, temos 2 versões do nginx convivendo, sendo balanceado via peso. Isso pode provocar algumas situações, como em uma requisição o usuário acessar uma versão da aplicação, e, numa nova requisição do mesmo usuário, outra versão. Imagine que na primeira versão ele tem um formulário de um jeito, e na outra o formulário muda. Isso trás uma experiência inconsistente. O stick session seria uma "sessão fixada" para o usuário. Através de uma forma de identificação do usuário, via consistent hash, uma aplicação, identificamos o usuário, e esse sempre acessará a mesma versão da primeira execução. O consistent hash pode ser criado via header, parâmetro, ip, entre outros. No nosso teste, usaremos um header para diferenciar. Para Isso, criaremos o arquivo consistent-hash, com virtualservice e destination rule parecido com o do exemplo anterior, mas com algumas modificações importantes:

```
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: nginx-vs
spec:
  hosts:
  - nginx-service
  http:
    - route:
      - destination:
          host: nginx-service
          subset: all


---

apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: nginx-dr
spec:
  host: nginx-service
  trafficPolicy:
    loadBalancer:
      consistentHash:
        httpHeaderName: "x-user"
  subsets:
    - name: all
      labels:
        app: nginx
```

No VirtualService, temos agora apenas 1 subset que atenderá a todas as versões. A nossa trafficPolicy em DestinationRule terá um atributo consistentHash que definirá que o header *x-user* identificará um usuário. Vamos aplicar o arquivo. Entraremos em um dos pods e executaremos *curl* algumas vezes para a nossa url, mas agora utilizando esse header, e vamos ver o que irá acontecer:

```
fabio@DESKTOP-234:~/fullcycle/istio$ kubectl apply -f deployment.yml
deployment.apps/nginx configured
deployment.apps/nginx-b configured
service/nginx-service unchanged

fabio@DESKTOP-234:~/fullcycle/istio$ kubectl get pods
NAME                             READY   STATUS    RESTARTS       AGE
fortio-deploy-689bd5969b-h7fvb   2/2     Running   2 (7h4m ago)   6d20h
nginx-b-54bd548c87-lvnt4         2/2     Running   2 (7h4m ago)   6d20h
nginx-5679dcd68b-ls86h           2/2     Running   2 (7h4m ago)   6d20h

fabio@DESKTOP-234:~/fullcycle/istio$ kubectl exec -it nginx-5679dcd68b-ls86h -- bash
Full Cycle Aroot@nginx-5679dcd68b-ls86h:/# curl --header "x-user: fabio" http://nginx-service:8000
Full Cycle Aroot@nginx-5679dcd68b-ls86h:/# curl --header "x-user: fabio" http://nginx-service:8000
Full Cycle Aroot@nginx-5679dcd68b-ls86h:/# curl --header "x-user: fabio" http://nginx-service:8000
Full Cycle Aroot@nginx-5679dcd68b-ls86h:/# curl --header "x-user: fabio" http://nginx-service:8000
Full Cycle Aroot@nginx-5679dcd68b-ls86h:/# curl --header "x-user: fabio" http://nginx-service:8000
Full Cycle Aroot@nginx-5679dcd68b-ls86h:/# curl --header "x-user: fabio" http://nginx-service:8000
Full Cycle Aroot@nginx-5679dcd68b-ls86h:/# curl --header "x-user: fabio" http://nginx-service:8000
Full Cycle Aroot@nginx-5679dcd68b-ls86h:/# curl --header "x-user: fabio" http://nginx-service:8000
Full Cycle Aroot@nginx-5679dcd68b-ls86h:/# curl --header "x-user: lopes" http://nginx-service:8000
Full Cycle Broot@nginx-5679dcd68b-ls86h:/# curl --header "x-user: lopes" http://nginx-service:8000
Full Cycle Broot@nginx-5679dcd68b-ls86h:/# curl --header "x-user: lopes" http://nginx-service:8000
Full Cycle Broot@nginx-5679dcd68b-ls86h:/# curl --header "x-user: lopes" http://nginx-service:8000
```

Podemos ver que na primeira chamada da url passando no header o x-user fabio, batemos no nginx A, após isso, toda chamada com esse valor no header bateu em A. Após isso, fizemos a chamada passando o x-user lopes, e bateu em B, e sempre que passamos esse valor batemos em B.


### Implementando circuit breaker

O Istio também possibilita a configuração de um circuit breaker apenas com configuração de um destination rule.

Para esse exemplo, vamos utilizar 2 deployments da mesma aplicação: 1 com um endpoint que responderá 200, outros que responderá 504. Para isso, vamos usar um deployment como o descrito abaixo:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: servicex
spec:
  selector:
    matchLabels:
      app: servicex
  template:
    metadata:
      labels:
        app: servicex
        version: "200"
    spec:
      containers:
      - name: servicex
        image: wesleywillians/circuit-breaker-example-go:latest
        ports:
        - containerPort: 8000

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: servicex-error
spec:
  selector:
    matchLabels:
      app: servicex
  template:
    metadata:
      labels:
        app: servicex
        version: "504"
    spec:
      containers:
      - name: servicex
        image: wesleywillians/circuit-breaker-example-go:error-504
        ports:
        - containerPort: 8000
        env:
          - name: error
            value: "yes"

---

apiVersion: v1
kind: Service
metadata:
  name: servicex-service
spec:
  type: ClusterIP
  selector:
    app: servicex 
  ports:
  - port: 80
    targetPort: 8000
```

Vamos aplicar esse deployment.

```
kubectl apply -f circuit-breaker/k8s/deployment.yml
```

Vamos executar o fortio com a instrução:

```
kubectl exec "$FORTIO_POD" -c fortio -- fortio load -c 2 -qps 0 -n 20 -loglevel Warning http://servicex-service
```

Se tudo der certo, teremos uma saída mostrando no fim a quantidade de requisições para cada status recebido:

```
Code 200 : 14 (70.0 %)
Code 504 : 5 (25.0 %)
Response Header Sizes : count 20 avg 115.6 +/- 75.68 min 0 max 166 sum 2312
Response Body/Total Sizes : count 20 avg 151.85 +/- 36.82 min 0 max 168 sum 3037
All done 20 calls (plus 0 warmup) 605.511 ms avg, 1.8 qps
```

Caso a chamada do fortio dê problema, pode ser interessante deletar o service e o deployment do fortio, e refazer a instalação. O mesmo pode ser feito também com o deployment/service do servicex.

Vamos agora criar um destinationrule com política de circuit breaker quando nós recebermos 5 erros de gateway num intervalo de 20s. E, após 30s ele voltará a fechar o circuito:

```
#circuit-breaker.yml

apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: circuit-breaker-servicex
spec:
  host: servicex-service.default.svc.cluster.local
  trafficPolicy:
    outlierDetection:
      # consecutive5xxErros: 20
      consecutiveGatewayErrors: 5
      interval: 20s
      baseEjectionTime: 30s
      maxEjectionPercent: 100
```
Vamos aplicar o arquivo:

```
kubectl apply -f circuit-breaker/k8s/deployment.yml
```

Vamos agora aplicar o fortio, agora com 200 requisições:

```
kubectl exec "$FORTIO_POD" -c fortio -- fortio load -c 2 -qps 0 -n 200 -loglevel Warning http://servicex-service
```

Nesse teste, após 5 chamadas reotrnando 504, abriu-se o circuito, mandando todas as requisições para o serviço disponível:

```
Code 200 : 195 (97.5 %)
Code 504 : 5 (2.5 %)
Response Header Sizes : count 200 avg 160.875 +/- 25.76 min 0 max 165 sum 32175
Response Body/Total Sizes : count 200 avg 166.295 +/- 4.409 min 137 max 167 sum 33259
All done 200 calls (plus 0 warmup) 51.328 ms avg, 32.6 qps
```

Fizemos um teste imediatamente após e todas as requisições foram com retoreno 200, porque o circuito ainda estava aberto.

```
Code 200 : 200 (100.0 %)
Response Header Sizes : count 200 avg 165 +/- 0 min 165 max 165 sum 33000
Response Body/Total Sizes : count 200 avg 167 +/- 0 min 167 max 167 sum 33400
All done 200 calls (plus 0 warmup) 1.507 ms avg, 1324.3 qps
```

### Implementando um gateway para acesso externo

Podemos expôr o nosso serviço externamente, mas de forma que um gateway receba o acesso e repasse para dentro do controle do istio, e assim todas as configurações de virtualservice, destinationrule funcione para tal.

Vamos verificar as configurações do ingressgateway do istio:

```
fabio@DESKTOP-34:~/fullcycle/istio$ kubectl get services -n istio-system
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)
               AGE
istiod                 ClusterIP      10.43.5.32      <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP            29d
prometheus             ClusterIP      10.43.125.153   <none>        9090/TCP
               25d
kiali                  ClusterIP      10.43.128.145   <none>        20001/TCP
               25d
tracing                ClusterIP      10.43.79.203    <none>        80/TCP,16685/TCP
               25d
zipkin                 ClusterIP      10.43.210.186   <none>        9411/TCP
               25d
jaeger-collector       ClusterIP      10.43.250.101   <none>        14268/TCP,14250/TCP,9411/TCP,4317/TCP,4318/TCP   25d
grafana                ClusterIP      10.43.255.26    <none>        3000/TCP
               25d
istio-ingressgateway   LoadBalancer   10.43.252.25    <pending>     15021:30993/TCP,80:30000/TCP,443:31874/TCP       29d
```

Podemos ver que a porta 80 do istio-ingressgateway bate na porta 30000, que é a porta do nodeport kubernetes configurado.

Outra coisa que podemos observar nesse serviço é que o acesso à porta 80 configurado está utilizando o protocolo http2. Vamos usar essas. Isso pode ser visto executando esse comando:

```
kubectl describe service istio-ingressgateway -n istio-s
ystem
```

Podemos editar a porta de redirecionamento do istio-ingressgateway caso a porta de binding com a 80 seja diferente de 30000, para o nosso exemplo:

```
kubectl edit svc istio-ingressgateway -n istio-system
```

Com essas informações, montaremos um gateway, que recebnerá qualquer host na porta 80 para fazer o encaminhamento. Vejamos as configurações do Gateway, VirtualService e DestinationRule:

```
#gateway.yml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: ingress-gateway-k3s
spec:
  selector:
    istio: ingressgateway
  servers:
    - port: 
        number: 80
        name: http
        protocol: http2
      hosts:
      - "*"
---

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: nginx-vs
spec:
  hosts: 
  - "*"
  gateways:
  - ingress-gateway-k3s
  http:
    - route:  
      - destination:
          host: nginx-service
          subset: v1
        weight: 100
      - destination:
          host: nginx-service
          subset: v2
        weight: 0

---

apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: nginx-dr
spec:
  host: nginx-service
  trafficPolicy:
    loadBalancer:
      simple: RANDOM
  subsets:
    - name: v1
      labels:
        version: A
      trafficPolicy:
        loadBalancer:
          simple: LEAST_CONN
    - name: v2
      labels:
        version: B
```


Criaremos um service do nginx, configurando port: 8000 e
targetPort: 80. Veja os nossos deployments e service:

```
#deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
        version: A
    spec:
      containers:
      - name: nginx
        image: wesleywillians/nginx-ab
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 80

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-b
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
        version: B
    spec:
      containers:
      - name: nginx
        image: wesleywillians/nginx-ab:b
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 80

---

apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 8000
    targetPort: 80
    nodePort: 30001
```

Vamos aplicar os ymls:

```
kubectl apply -f deployment.yml
kubectl apply -f gateway.yml
```

Se tudo funcionar conforme esperado, ao entrar no browser e digitar localhost:8000, além de conseguirmos conexão, receberemos sempre o texto "Full Cycle A", visto que a nossa destinationrule determinou que a v receberá 100% das requisições.

### Trabalhando com prefixos no gateway

No exemplo anterior, o controle de acesso a serviços implementados pelo nosso destinationrule utiliza randomicamente os pesos para cada serviço, no caso, 100% das chamadas para o serviço v1, e 0 para o v2. Vamos mudar a configuração para determinar que, acessarmos o prefixo */*, a reqquisição utilizará o serviço v1, todavia, se o prefixo utilizado na requisição for */b*, a destinação será o seriço v2. Para isso, atualizaremos o VirtualService:

```
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: nginx-vs
spec:
  hosts: 
  - "*"
  gateways:
  - ingress-gateway-k3s
  http:
    - match:
      - uri:
          prefix: "/b"
      route:
      - destination:
          host: nginx-service
          subset: v2
    - match:
      - uri: 
          prefix: "/"
      route:
      - destination:
          host: nginx-service
          subset: v1
```


Aplicaremos o nosso arquivo:

```
kubectl apply -f gateway.yml
```

O compoirtamento esperado é, quando acessarmos localhost:8000/, será exibida a mensagem "Full Cycle A". Caso seja localhost:8000/b, receberemos o retorno 404 do servidor, o que não é ruim. A questão é que como não configuramos nenhum serviço /b no nginx e nossa aplicação não tem esse endpoint, então recebemos not found.

### Trabalhanmdo com domínios no gateway

Podemos configurar virtualservices por domínio também. Para nosso teste local, iremos criar 2 domínios que no fim das contas será na nossa máquina local: a.fullcycle e b.fullcycle. Para isso, vamos editar o nosso arquivo de hosts do windows c:windows/system32/drivers/etc/hosts, adicionando o mapeamento:

```
localhost a.fullcycle b.fullcycle
```

Após isso, vamos implementar 2 virtualservices. nginx-vs escutará o host a.fullcycle e chamará o subset v1, o virtualservice nginx-vs-b escutará o host b.fullcycle e chamará o subset v2.

```
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: nginx-vs
spec:
  hosts: 
  - "a.fullcycle"
  gateways:
  - ingress-gateway-k3s
  http:
    - route:
      - destination:
          host: nginx-service
          subset: v1

---

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: nginx-vs-b
spec:
  hosts: 
  - "b.fullcycle"
  gateways:
  - ingress-gateway-k3s
  http:
    - route:
      - destination:
          host: nginx-service
          subset: v2
```

Aplicaremos o gateway modificado:

```
kubectl apply -f gateway.yml
```

Se tudo der certo, ao acessar no browser a.fullcycle:8000, receberemos a mensagem "Full Cycle A", e ao acessar b.fullcycle:8000/, receberemos Full Cycle B.
