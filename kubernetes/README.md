## Kubernetes

Alguns tipos importantes de objetos: **deployments**, **replicasets**, **pods**  

visualização de objetos existentes:

```
kubectl get <tipo>
```

### Implantação de yml
kubectl apply -f <nome_arquivo yml>

### Descrição do objetos
kubectl describe <tipo> <objeto>


### Histórico de atualizações de um objeto
kubectl rollout history <tipo> <objeto>


###Considerações deployments

```
<!-->Exemplo de deployment<-->
apiVersion: apps/v1
kind: Deployment
metadata:
  name: goserver
  labels:
    app: goserver
spec:
  selector:
    matchLabels:
      app: goserver
  replicas: 10
  template:
    metadata:
      labels:
        app: goserver
    spec:
      containers:
      - name: goserver
        image: fabiobione/hello-go:v2
```

É um deployment simples, que cria 1 replicaset responsável por criar 10 pods sobre a img determinada. Nesse caso, imaginamos que o replicaset recebe um hash como id, que fará parte do nome de todos os pods, e cada pod terá um hash final único. Ex.

```
fabio@DESKTOP-1111:~/fullcycle$ kubectl get replicasets
NAME                  DESIRED   CURRENT   READY   AGE
goserver-65d65bf777   10        10        10      97m
goserver-c5b49f45b    0         0         0       101m
```

```
fabiobione@DESKTOP-4KRU5T4:~/fullcycle$ kubectl get pods
NAME                        READY   STATUS    RESTARTS   AGE
goserver-65d65bf777-2hskh   1/1     Running   0          97m
goserver-65d65bf777-2tqhs   1/1     Running   0          98m
goserver-65d65bf777-478dw   1/1     Running   0          98m
goserver-65d65bf777-4q78z   1/1     Running   0          96m
goserver-65d65bf777-6rkjf   1/1     Running   0          96m
goserver-65d65bf777-b9fpx   1/1     Running   0          97m
goserver-65d65bf777-bsszb   1/1     Running   0          98m
goserver-65d65bf777-jknvk   1/1     Running   0          98m
goserver-65d65bf777-tt6kh   1/1     Running   0          98m
goserver-65d65bf777-xhn68   1/1     Running   0          97m
```

Podemos ver que o o nome de cada pod fica assim: <name_deployment>-<id_replicaset>-<id_pod>

Se esse replicaset tem alguma alteração, como por exemplo a imagem, um novo replicaset será criado, e o kubernetes irá fazer a substituição gradual dos pods, e isso faz com que não haja downtime na aplicação.

### Alterando a versão do deployment

```
kubectl rollout undo deployment goserver
```

Nesse comando, voltaremos para a última versão, mas se quiséssemos ir para outra versão espacífica, adicionaríamos na instrução a flag --to-revision=<versão>.


## Services

### Exemplo de um service
```
apiVersion: v1
kind: Service
metadata:
  name: goserver-service
spec:
  selector:
    app: goserver
  type: ClusterIP
  ports:
  - name: goserver-service
    port: 80
    protocol: TCP

```

Um service permite que um pod de uma aplicação torne-se acessível. No nosso caso definimos o nome do nosso service via metadata.name. Especificamos que ele será aplicado via seletor com app __goserver__. Se observarmos, no nosso deployment temosum seletor indicadno esse app, então o service entenderá que, por ter no seletor o mesmo app, poderá ser aplicado nos pods daquele deployment.

Vamos criar o service:

```
fabio@DESKTOP-2222:~/fullcycle$ kubectl apply -f k8s/service.yml
service/goserver-service created
```

Vamos agora ver esse service criado, com a porta acessível que escolhemos:

```
fabio@DESKTOP-3333:~/fullcycle$ kubectl get services
NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
goserver-service   ClusterIP   10.96.239.77   <none>        80/TCP    8s
kubernetes         ClusterIP   10.96.0.1      <none>        443/TCP   76d
```

Importante observar que, com a configuração que implantamos, temos apenas um ip interno. Então apenas os pods dentro do kubernetes poderão acesssar o service.

Uma alterantiva para acessar externamente é fazer port-forward de porta:

```
kubectl port-forward svc/goserver-se
rvice 8000:80
```

Se acessarmos no browser localhost:8000, veremos a mensagem de funcionamento do goserver.


### port x targetPort

Dentro do service, quando definimos um port, determinamos que o service será acessível via aquela porta. Já o targetPort define qual porta do pod o service tentará acessar. Caso não tenha definição de targetPort no service.yml, o kubernetes entenderá que a porta acessível do service será a mesma do pod. Imaginando por exemplo uma aplicação que seja acessada pela porta 8000, e o service via porta 80, a configuração do service seria port: 80 e targetPort: 8000.

### Acessando api do kubernetes

```
kubectl proxy --port=8080
```

Com esse comando, podemos ver todas as apis do kubernetes acessando localhost:8080

Para ver definições do service por exemplo:

```
http://localhost:8080/api/v1/namespaces/default/services/goserver-service
```

### Tipo LoadBalancer
```
apiVersion: v1
kind: Service
metadata:
  name: goserver-service
spec:
  selector:
    app: goserver
  type: LoadBalancer
  ports:
  - name: goserver-service
    port: 80
    targetPort: 8000
    protocol: TCP

```

O tipo loadBalancer gera um ip exclusivo externo para utilização, e faz o balanceamento de carga das requisições por réplica.

### Trabalhando com variáveis de ambiente

No arquivo server.go, pegaremos valores de variáveis de ambiente:

```
package main

import "net/http"
import "os"
import "fmt"

func main() {
	http.HandleFunc("/", Hello)
	http.ListenAndServe(":8000", nil)
}

func Hello(w http.ResponseWriter, r *http.Request) {
	name := os.Getenv("NAME")
	age := os.Getenv("AGE")

	fmt.Fprintf(w, "Hello, I'm %s. I'm %s", name, age)
}
```

Subiremos uma nova imagem do hello-go:

```
docker build -t fabiobione/hello-go:v4 .
```
```
docker push fabiobione/hello-go:v4
```

Agora vamos inserir no deployment as variáveis através do atributo **env**:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: goserver
  labels:
    app: goserver
spec:
  selector:
    matchLabels:
      app: goserver
  replicas: 10
  template:
    metadata:
      labels:
        app: goserver
    spec:
      containers:
      - name: goserver
        image: fabiobione/hello-go:v4
        env:
          - name: name
            value: "Bione"
          - name: AGE
            value: "38"
```

Quando dermos o comando de apply e o port-forward, Teremos printado na tela a mensagem com as variáveis inseridas.

### ConfigMap

POdemos separar as variáveis de ambiente em um arquivo do tipo ConfigMap. Vamos criá-lo:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: goserver-env
data:
  NAME: "Bione"
  AGE: "38"
```


Com essa mudança, vamos atualizar o deployment, que agora irá pegar o valor das variáveis por referência aos contidos no configmap-env (goserver-env):

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: goserver
  labels:
    app: goserver
spec:
  selector:
    matchLabels:
      app: goserver
  replicas: 10
  template:
    metadata:
      labels:
        app: goserver
    spec:
      containers:
      - name: goserver
        image: fabiobione/hello-go:v4
        env:
          - name: NAME
            valueFrom:
              configMapKeyRef:
                name: goserver-env
                key: NAME
          - name: AGE
            valueFrom:
              configMapKeyRef:
                name: goserver-env
                key: AGE
```

Importante salientar que, caso haja alteração de valores do configmap, é necessário fazer apply no deployment para que ele consiga pegar a nova referência, senão permanece com valores antigos.

```
kubectl apply -f k8s/configmap-env.yml
```
```
kubectl apply -f k8s/deployment.yaml
```