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


### Considerações deployments

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

Podemos separar as variáveis de ambiente em um arquivo do tipo ConfigMap. Vamos criá-lo:

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

Uma forma de expôr todas as variáveis de um configmap seria apenas referenciando o name do configmap, e automaticamente temos acesso a todas as suas vars.

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
        envFrom:
          - configMapRef:
              name: goserver-env
```


### Injetando Configmap na aplicação

Vamos imaginar um cenário onde precisaremos injetar arquivos na aplicação, tanto arquivos novos, como substituição de arquivos. Podemos usar configmaps para substituit, por exemplo arquivos confs, ou qualquer outro.

Vamos criar um novo endpoint no server.go, ponde ele pegará dados de um arquivo que não está pré definido no projeto:

Adicionando os imports:
```
import "io/ioutil"
import "log"
```

Adicionando agora o novo endpoint:
```
func main() {
	http.HandleFunc("/configmap", ConfigMap)
. . .
```

E a nova função que pegará os dados do arquivo:

```
func ConfigMap(w http.ResponseWriter, r *http.Request) {
	data, err := ioutil.ReadFile("myFamily/family.txt")
	if err != nil {
		log.Fatalf("Error reading file: ", err)
	}

	fmt.Fprintf(w, "My family: %s", string(data))
}
```

Ainda não existe o arquivo "myFamily/family.txt". Vamos criar um novo configmap que servirá de base para a criação do arquivo:

__configmap-family.yml__
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-family
data:
  members: "Fabio, Izabel"
```


Agora vamos fazer 2 coisas: 1. fazer push na imagem do hello-go; 2. apply no novo configmap:

```
docker build -t fabiobione/hello-go:v5 .

docker push fabiobione/hello-go:v5
```

```
kubectl apply -f k8s/configmap-family.yml
```

Agora precisamos fazer algumas alterações no deployment, começando por atualizar a versão da imagem:

```
      containers:
      - name: goserver
        image: fabiobione/hello-go:v5
```

Vamos agora criar um volume na spec do template, onde o volume se chamará config, referenciará o configmap-family, e os dados será extraídos da key members do arquivo family.txt:

```
      volumes:
        - name: config
          configMap:
            name: configmap-family
            items:
            - key: members
              path: "family.txt"
```

E agora em containers, vamos montar o volume no caminho desejado:

```
        volumeMounts:
          - mountPath: "/go/myFamily"
            name: config
```

Agora vamos dar apply no deployment e fazer port-forward. Se tudo der certo,ao acessar http://localhost:9000/configmap, será apresentado "My family: Fabio, Izabel"

```
kubectl apply -f k8s/deployment.yaml

kubectl port-forward svc/goserver-service 9000:80
```

Apenas para visualização, vamos entar em um dos pods para ver o arquivo:

```
fabio@DESKTOP-5555:~/fullcycle/kubernetes$ kubectl get pods
NAME                        READY   STATUS              RESTARTS   AGE
goserver-544bdcccb6-4r7vr   0/1     ContainerCreating   0          7s
goserver-544bdcccb6-hrztn   1/1     Running             0          7s
goserver-544bdcccb6-jjkrx   0/1     ContainerCreating   0          7s
goserver-544bdcccb6-mxgqz   0/1     ContainerCreating   0          7s
goserver-544bdcccb6-t8fwg   0/1     ContainerCreating   0          7s
goserver-7fc6b5fcdf-blb4p   1/1     Running             0          5d1h
goserver-7fc6b5fcdf-cflvs   1/1     Running             0          5d1h
goserver-7fc6b5fcdf-ddjrz   1/1     Running             0          5d1h
goserver-7fc6b5fcdf-fbbm7   1/1     Running             0          5d1h
goserver-7fc6b5fcdf-g2zm9   1/1     Running             0          5d1h
goserver-7fc6b5fcdf-g59vg   1/1     Running             0          5d1h
goserver-7fc6b5fcdf-hxlrk   1/1     Running             0          5d1h
goserver-7fc6b5fcdf-qls8x   1/1     Running             0          5d1h

kubectl exec -it goserver-544bdcccb6-4r7vr -- bash
root@goserver-544bdcccb6-4r7vr:/go# ls myFamily/
family.txt
```


### Adicionando uma secret

Vamos criar mais uma function no server.go:

```
http.HandleFunc("/secret", Secret)
. . . 

func Secret(w http.ResponseWriter, r *http.Request) {
	user := os.Getenv("USER")
	password := os.Getenv("PASSWORD")

	fmt.Fprintf(w, "User: %s. Password %s", user, password	)
}
```

Bem parecido com o hello, temos variáveis user e password vindos de varipaveis de ambiente, mas como são informações mais sensíveis, vamos ofuscar elas em secret:
```
docker build -t fabiobione/hello-go:v5.1 .

docker push fabiobione/hello-go:v5.1
```


secret.yml
```
apiVersion: v1
kind: Secret
metadata:
  name: goserver-secret
type: Opaque
data:
  USER: RmFiaW8K
  PASSWORD: MTIzNDU2NzgK
```

Aplicaremos esse arquivo.
```
kubectl apply -f k8s/secret.yml
```

Vamos atualizar a versão da imagem, e inserir o secretRef:
```
      containers:
      - name: goserver
        image: fabiobione/hello-go:v5.1
        envFrom:
          - configMapRef:
              name: goserver-env
          - secretRef:
              name: goserver-secret
```
E agora aplicar o deployment:
```
kubectl apply -f k8s/deployment.yaml

kubectl port-forward svc/goserver-service 9000:80
```

Se tudo der certo, ao digitar **http://localhost:9000/secret**, receberemos o retorno (já decodificado):

User: Fabio
. Password 12345678


### Liveness probe

O kubernetes tem um recurso configurável para verificação de saúde de uma aplicação, o **livenessProbe**. Para demonstrar o funcionamento, vamos criar um endpoint no server.go __/healthz__, Onde quandoa a plicação subir teremos um contador de tempo. A partir de 25 segundos de subida, sempre que o endpoint for chamado, ele vai propositalmente retornar um erro 500:

```
import (
	"net/http"
	"os"
	"fmt"
	"io/ioutil"
	"log"
	"time"	
)

var startedAt = time.Now() 

func main() {
	http.HandleFunc("/healthz", Healthz)
	http.HandleFunc("/secret", Secret)
	http.HandleFunc("/configmap", ConfigMap)
	http.HandleFunc("/", Hello)
	http.ListenAndServe(":8000", nil)
}

. . . 

func Healthz(w http.ResponseWriter, r *http.Request) {
	duration := time.Since(startedAt)
	if duration.Seconds() > 25 {
		w.WriteHeader(500)
		w.Write([]byte(fmt.Sprintf("Duration: %v", duration.Seconds())))
	}else{
		w.WriteHeader(200)
		w.Write([]byte("Ok"))
	}
}
```

Vamos criar uma nova versão do hello-go:
```
docker build -t fabiobione/hello-go:v5.2 .

docker push fabiobione/hello-go:v5.2
```

Agora vamos implementar o livenesseProbe definindo que serão necessárias 5 chamadas do healthz na porta 8000 bem sucedidas para considerar 1 sucesso, e cada chamada terá 1 segundo de timeout, passando disso, será considerado falha. E o limite de falha para o container reiniciar é 1:

```
    spec:
      containers:
      - name: goserver
        image: fabiobione/hello-go:v5.2
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8000
          periodSeconds: 5
          failureThreshold: 1
          timeoutSeconds: 1
          successThreshold: 1
```


Vamos aplicar o deployment e ao mesmo tempo observar os restats com o tempo:
```
kubectl apply -f k8s/deployment.yaml && watch -n1 kubectl get pods
```


Antes dos 25 segundos:
```
NAME                        READY   STATUS    RESTARTS   AGE
goserver-745bf5dc4b-2lkvd   1/1     Running   0          24s
goserver-745bf5dc4b-5247f   1/1     Running   0          24s
goserver-745bf5dc4b-b2j5m   1/1     Running   0          24s
goserver-745bf5dc4b-bbwpx   1/1     Running   0          24s
goserver-745bf5dc4b-bc47k   1/1     Running   0          24s
goserver-745bf5dc4b-k9t67   1/1     Running   0          24s
goserver-745bf5dc4b-n8w8n   1/1     Running   0          24s
goserver-745bf5dc4b-pd6xw   1/1     Running   0          24s
goserver-745bf5dc4b-sx8k8   1/1     Running   0          24s
goserver-745bf5dc4b-vvdhq   1/1     Running   0          24s
```

Agora depois dos 25 segundos, com o endpoint respondendo erro 500:

```
NAME                        READY   STATUS    RESTARTS      AGE
goserver-745bf5dc4b-2lkvd   1/1     Running   1 (16s ago)   47s
goserver-745bf5dc4b-5247f   1/1     Running   1 (16s ago)   47s
goserver-745bf5dc4b-b2j5m   1/1     Running   1 (16s ago)   47s
goserver-745bf5dc4b-bbwpx   1/1     Running   1 (16s ago)   47s
goserver-745bf5dc4b-bc47k   1/1     Running   1 (16s ago)   47s
goserver-745bf5dc4b-k9t67   1/1     Running   1 (16s ago)   47s
goserver-745bf5dc4b-n8w8n   1/1     Running   1 (16s ago)   47s
goserver-745bf5dc4b-pd6xw   1/1     Running   1 (16s ago)   47s
goserver-745bf5dc4b-sx8k8   1/1     Running   1 (16s ago)   47s
goserver-745bf5dc4b-vvdhq   1/1     Running   1 (16s ago)   47s
```


### readinessProbe

Existem situações onde precisamos que um container só esteja pronto quando ele está totalmente ok. Imagine um container que sobe contextos, faz conexão com banco de dados, com filas, e outras dependências externas. Acessar ele antes de todas essas dependências estarem estabelecidas retornará erro porque ele não está pronto. Uma forma de garantir que ele seja acessado apenas quando estiver pronto é o readinessProbe. E para demonstrar, vamos editar o método healthz, definindo que até 10 segundos pós a subida, ele estará indisponível, e depois disso, estará pronto:

```
func Healthz(w http.ResponseWriter, r *http.Request) {
	duration := time.Since(startedAt)
	if duration.Seconds() < 10 {
		w.WriteHeader(500)
		w.Write([]byte(fmt.Sprintf("Duration: %v", duration.Seconds())))
	}else{
		w.WriteHeader(200)
		w.Write([]byte("Ok"))
	}
}
```
Vamos criar nova versão do hello-go:
```
docker build -t fabiobione/hello-go:v5.3 .

docker push fabiobione/hello-go:v5.3
```

Vamos comentar todoo bloco de livenessProbe (depois retornaremos a ele). Criaremos um readinessProbe, definindo um delay inicial de 10 segundos, e a cada 3 segundos será feita uma verificação, e 1 falha será suficiente para definir que o container ainda não está pronto.

```
    spec:
      containers:
      - name: goserver
        image: fabiobione/hello-go:v5.3
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8000
          periodSeconds: 3
          failureThreshold: 1
          initialDelaySeconds: 10
        # livenessProbe:
        #   httpGet:
        #     path: /healthz
        #     port: 8000
        #   periodSeconds: 5
        #   failureThreshold: 1
        #   timeoutSeconds: 1
        #   successThreshold: 1
```

Agora vamos aplicar o deployment e observar que apenas após 10 segundos a aplicação será considerada pronta

```
kubectl apply -f k8s/deployment.yaml && watch -n1 kubectl get pods
```

Obs: TRabalhar com readinessProbe em conjunto com livenessProbe é um tanto desafiador, visto que, olhando do ponto de vista do exemplo implementado, o livenesse sempre irá impactar o readiness. Uma forma de resolver isso é através do startupProbe, que garante um estado incial,e só depois disso o readiness e o liveness passam a funcionar.

Vamos ver como fica a configuração no deployment:
```
      containers:
      - name: goserver
        image: fabiobione/hello-go:v5.4
        startupProbe:
          httpGet:
            path: /healthz
            port: 8000
          periodSeconds: 3
          failureThreshold: 30
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8000
          periodSeconds: 3
          failureThreshold: 1
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8000
          periodSeconds: 5
          failureThreshold: 1
          timeoutSeconds: 1
          successThreshold: 1
```

Vamos atualizar o deployment:
```
kubectl apply -f k8s/deployment.yaml && watch -n1 kubectl get pods
```

O que perceberemos é que após os 10 segundos, a aplicação/container estará disponível. E, após os 30 segundos, não estará disponível por conta do reeadinessProbe, e depois será reiniciado como efeito do livenessProbe, e aí começamos novamente com o startupProbe.


## Preparativos para trabalhar com recursos

### Instalando metrics-server

O metrics server é um servidor de métricas. Vamos instalar ele no kind, mas precisaremos fazer uma adaptação para isso, pois o metris-server precisa de uma conexão de containeres segura, e para isso vamos inserir no components.yml uma flag para permitir conexões não seguras.

Primeiro vamos baixar o arquivo componentes, e depois renomear, para não confundirmos.

```
wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

mv components.yaml metrics-server.yaml
```

Agora vamos abrir o arquivo, e procurar no deployment __kind: Deployment__, e aonde houver __- args:__ vamos adicionar a flag --kubelet-insecure-tls:

```
      - args:
        - --cert-dir=/tmp
        - --secure-port=10250
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls
```

Após isso, vamos executar o apply do arquivo yaml. E também verificar apiservices. Destque para o service _kube-system/metrics-server_, que precisa estar disponível.

```
kubectl apply -f metrics-server.yaml


fabio@DESKTOP-34536345:~/fullcycle/kubernetes/k8s$ kubectl get apiservices
NAME                                   SERVICE                      AVAILABLE   AGE
v1.                                    Local                        True        107d
v1.admissionregistration.k8s.io        Local                        True        107d
v1.apiextensions.k8s.io                Local                        True        107d
v1.apps                                Local                        True        107d
v1.authentication.k8s.io               Local                        True        107d
v1.authorization.k8s.io                Local                        True        107d
v1.autoscaling                         Local                        True        107d
v1.batch                               Local                        True        107d
v1.certificates.k8s.io                 Local                        True        107d
v1.coordination.k8s.io                 Local                        True        107d
v1.discovery.k8s.io                    Local                        True        107d
v1.events.k8s.io                       Local                        True        107d
v1.networking.k8s.io                   Local                        True        107d
v1.node.k8s.io                         Local                        True        107d
v1.policy                              Local                        True        107d
v1.rbac.authorization.k8s.io           Local                        True        107d
v1.scheduling.k8s.io                   Local                        True        107d
v1.storage.k8s.io                      Local                        True        107d
v1beta1.metrics.k8s.io                 kube-system/metrics-server   True        106s
v1beta2.flowcontrol.apiserver.k8s.io   Local                        True        107d
v1beta3.flowcontrol.apiserver.k8s.io   Local                        True        107d
v2.autoscaling                         Local                        True        107d
```

### Conceito de vCPU

Trata-se de unidade de medida medida por milicore, onde 100m equivale a 1 cpu completo. 500m seria metade de um cpu. 


### Resources

Vamos definir os recursos mínimos de nossos pods, e o limite de utilização, tanto de memória quanto cpu:

```
      containers:
      - name: goserver
        image: fabiobione/hello-go:v5.4

        resources:
          requests:
            cpu: 100m
            memory: 20Mi
          limits:
            cpu: 500m
            memory: 25Mi
```

Agora iremos aplicar a atualização:

```
kubectl apply -f deployment.yaml
```

Vamos fazer um top no pod para ver quanto de recursos está utilizando.

```
fabio@DESKTOP-dsdsdfd:~/fullcycle/kubernetes/k8s$ kubectl top pod goserver-5bb75f99bd-rf8m4
NAME                        CPU(cores)   MEMORY(bytes)
goserver-5bb75f99bd-rf8m4   5m           2Mi
```

### Horizontal Auto Scaler (HPA)

HPA é um tipo de objeto que controla, via configurações, quantidade mínima e máxima de escalabilidade de um deployment (ou outro tipo), como escala mínima é maxima, e critérios de escala e desescala.

Veremos um kind hpa com definição de replicas e  critério de escala baseado na utilização de CPU:

Para esse teste, usaremos uma versão do serve.go, apenas trocando _if duration.Seconds() < 10 || duration.Seconds() > 30 {_ por _if duration.Seconds() < 10 {_. Dessa forma, pararemos de tomar erro após 30 segundos, que provocar reinicialização até dar crash na aplicação.

Poderemos ver que estamos aplicando em _scaleTargetRef>kind_ e _scaleTargetRef>name_, ou seja, estamos aplicando essa auto escala no deployment de nome goserver.

```
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: goserver-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: goserver
  minReplicas: 1
  maxReplicas: 5
  targetCPUUtilizationPercentage: 75
```

```
kubectl apply -f hpa.yaml

fabio@DESKTOP-gfgdfgdf454:~/fullcycle/kubernetes/k8s$ kubectl get hpa
NAME           REFERENCE             TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
goserver-hpa   Deployment/goserver   1%/75%    1         5         1          9m53s
```

### Testando o hpa através de teste de stress Fortio

 [Github fortio](https://github.com/fortio/fortio). Para estressar nossa aplicação, e assim ver ele escalar, vamos fazer várias requisições com ajuda do Fortio, ferramenta de testes de estress.
  Vamo solicitar ao kubectl que rode um pod da imagem do fortio, carregando alguns parâmetros próprios dele, como determinando 800 requisições por segundo (qps), e isso por 120 segundos (t), e isso será executado por 70 processos simultâneos (c), na nossa url de Helthz. 

  ```
  kubectl run -it fortio --rm --image=fortio/fortio -- load -qps 800 -t 120s -c 70 "http://goserver-service/healthz"
  ```

Nesse caso, podemos acompanhar as escalas de replicas através do comando:

```
watch -n1 kubectl get hpa
NAME           REFERENCE             TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
goserver-hpa   Deployment/goserver   2%/75%    1         5         3          51m
```

### Volume persistente com PersistentVolumeClaim

PersistentVolumeClaim é um tipo que usamos para solicitar um volume persistente, que poderá ser usado por containeres.

Vamos criar um volume de 5gb para ser utilizado pelo goserver.

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: goserver-pvc
spec:
  resources:
    requests:
      storage: 5Gi
  accessModes:
    - ReadWriteOnce
```

Podemos perceber que a nossa claim está pendente, e o motivo pode ser visto na storageclass, que está aguardando a primeira utilização do storage para ser criado.

```
kubectl apply -f k8s/pvc.yaml
fabio@DESKTOP-123242:~/fullcycle/kubernetes$ kubectl get pvc
NAME           STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
goserver-pvc   Pending                                      standard       22s
fabio@DESKTOP-123242:~/fullcycle/kubernetes$ kubectl get storageclass
NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
standard (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false
     140d
```


Agora vamos adicionar esse volume no deployment, adicionando em volumeMounts. Primeiro vamos adicionar em volumes o persistentVolumeClaim goserver-pvc, criado no passo anterior, após, adicionaremos esse volume criado em volumeMounts:

```
...
        volumeMounts:
          - mountPath: "/go/myFamily"
            name: config
          - mountPath: "/go/pvc"
            name: goserver-volume
... 
      volumes:
        - name: goserver-volume
          persistentVolumeClaim:
            claimName: goserver-pvc
```

Agora vamos aplicar o deployment.

```
kubectl apply -f k8s/deployment.yaml
```

Após isso, podemos verificar que o pvc criado mudou de status, visto que agora foi requisitado deplo nosso deployment:

```
fabio@DESKTOP-34565436:~/fullcycle/kubernetes$ kubectl get pvc
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
goserver-pvc   Bound    pvc-c50dadee-5248-4759-a7d7-6f01e1b6b051   5Gi        RWO            standard       14m
```

Façamos um teste de volume. Vamos entrar num container, na pasta pvc mapeada pelo volume e criar um arquivo. Após isso iremos deletar o pod. Se tudo der certo, no pod que será criado, deverá ter esse arquivo dentro da mesma pasta, mesmo sendo um novo pod:

```
fabiobione@DESKTOP-4KRU5T4:~/fullcycle/kubernetes$ kubectl exec -it goserver-749cb49946-svgt6 -- bash
root@goserver-749cb49946-svgt6:/go# ls
bin  myFamily  pvc  server  server.go  src
root@goserver-749cb49946-svgt6:/go# cd pvc
root@goserver-749cb49946-svgt6:/go/pvc# touch oi
root@goserver-749cb49946-svgt6:/go/pvc# ls
oi
exit


fabio@DESKTOP-2345:~/fullcycle/kubernetes$ kubectl delete pod goserver-749cb49946-svgt6
pod "goserver-749cb49946-svgt6" deleted
```

Pegaremos outro pod dentro do contexto goserver:

```
fabio@DESKTOP-1:~/fullcycle/kubernetes$ kubectl get pods
NAME                        READY   STATUS    RESTARTS   AGE
goserver-749cb49946-hgd6c   1/1     Running   0          39s

fabio@DESKTOP-23:~/fullcycle/kubernetes$ kubectl exec -it goserver-749cb49946-hgd6c -- bash
root@goserver-749cb49946-hgd6c:/go# ls
bin  myFamily  pvc  server  server.go  src
root@goserver-749cb49946-hgd6c:/go# ls pvc
oi
root@goserver-749cb49946-hgd6c:/go#
```

Poidemos ver dessa forma que de fato o arquivo criado no volume está persistido.


### Criando pods ordenados com statefulsets

Imagine um cenário onde Temos que criar um banco de dados, sendo 1 pod principal e alguns slaves dessa base de dados. Para esse cenário, seria importante garantir a seguinte ordem: a primeira subida ser o pod principal, da base, e o restante sequencialmente. Da mesma forma, quando for excluir ou desescalar, excluir do maior para o menor, como uma pilha. Isso é possível usando statefulset. Vamos criar o exemplo proposto, baseado no mysql, com 5 réplicas. O comportamento será parecido com o de um deployment, mas a escala será ordenada.

statefulset.yaml:
```
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql-h
  replicas: 5
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - name: mysql
          image: mysql
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: root
```

Aplicando o arquivo:

```
fabio@DESKTOP-213:~/fullcycle/kubernetes$ kubectl apply -f k8s/statefulset.yaml
statefulset.apps/mysql created
```

Podemos ver aqui que os names seguiram uma sequencia.

```
fabiobione@DESKTOP-4KRU5T4:~/fullcycle/kubernetes$ kubectl get po
NAME                        READY   STATUS    RESTARTS   AGE
goserver-749cb49946-hgd6c   1/1     Running   0          33m
mysql-0                     1/1     Running   0          2m53s
mysql-1                     1/1     Running   0          117s
mysql-2                     1/1     Running   0          65s
mysql-3                     1/1     Running   0          15s
mysql-4                     1/1     Running   0          14s
```


Apenas a título de exploração, vamos setar apenas 4 réplicas manualmente e ver se ele excluirá o mysql-4:

```
fabio@DESKTOP-34:~/fullcycle/kubernetes$ kubectl scale statefulset mysql --replicas=4
statefulset.apps/mysql scaled
fabio@DESKTOP-34:~/fullcycle/kubernetes$ kubectl get po
NAME                        READY   STATUS    RESTARTS   AGE
goserver-749cb49946-hgd6c   1/1     Running   0          41m
mysql-0                     1/1     Running   0          10m
mysql-1                     1/1     Running   0          9m26s
mysql-2                     1/1     Running   0          8m34s
mysql-3                     1/1     Running   0          7m44s
```

### Criando headless services

Em alguns cenários iremos querer controlar as réplicas via nomenclatura, e não endereços. Imagine um cenário onde temos 5 pods do mysql. Queremos que o 1º seja apenas de gravação, e o restante de leitura. Uma alterantiva seria criar uma service headless, sem ip externo, onde o dns do kubernetes irá resolver qual pod será selecionado via nomenclarura.

Vamo criar um service simples. O diferencial nesse caso será que ele não terá valor definido para clusterIp (clusterIP: None).

mysql-service-h.yaml
```
apiVersion: v1
kind: Service
metadata:
  name: mysql-h
spec:
  selector:
    app: mysql
  ports:
    - port: 3306
  clusterIP: None
```

Note que o name bate com o name do statefulset, garantindo que o statefulset irá usar o serviço que criaremos.

Vamos aplicar os arquivos:

```
fabio@DESKTOP-435:~/fullcycle/kubernetes$ kubectl apply -f k8s/statefulset.yaml
statefulset.apps/mysql created
fabio@DESKTOP-435:~/fullcycle/kubernetes$ kubectl apply -f k8s/mysql-service-h.yml
service/mysql-h created
fabio@DESKTOP-435:~/fullcycle/kubernetes$ kubectl get service
NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
goserver-service   ClusterIP   10.96.239.77   <none>        80/TCP     83d
kubernetes         ClusterIP   10.96.0.1      <none>        443/TCP    160d
mysql-h            ClusterIP   None           <none>        3306/TCP   7s
fabio@DESKTOP-435:~/fullcycle/kubernetes$ kubectl get statefulset
NAME    READY   AGE
mysql   5/5     27s
fabio@DESKTOP-435:~/fullcycle/kubernetes$ kubectl get pods
NAME                        READY   STATUS    RESTARTS      AGE
goserver-749cb49946-hgd6c   1/1     Running   2 (18m ago)   19d
mysql-0                     1/1     Running   0             2m7s
mysql-1                     1/1     Running   0             2m4s
mysql-2                     1/1     Running   0             2m2s
mysql-3                     1/1     Running   0             2m
mysql-4                     1/1     Running   0             117s
```

Agora faremos o seguinte: Vamos acessar o bash do pod goserver-749cb49946-hgd6c, e dentro dele iremos pingar o primeiro pod do mysql nomenclatura <nome-pod>.<nome-service>. Ou seja, para acessar o 1º daremos _ping mysql-0.mysql-h_, e o 2º _ping mysql-1.mysql-h_.

```
kubectl exec -it goserver-749cb49946-hgd6c -- bash

root@goserver-749cb49946-hgd6c:/go# ping mysql-0.mysql-h
PING mysql-0.mysql-h.default.svc.cluster.local (10.244.3.4) 56(84) bytes of data.
64 bytes from mysql-0.mysql-h.default.svc.cluster.local (10.244.3.4): icmp_seq=1 ttl=62 time=0.099 ms
64 bytes from mysql-0.mysql-h.default.svc.cluster.local (10.244.3.4): icmp_seq=2 ttl=62 time=0.084 ms
```

Dessa forma, seria simples chamar separadamente os pods tanto de escrita (mysql-0.mysql-h) quanto de leitura, sendo do índice 1 ao 4.


### Criação de volumes dinâmicos com statefulset

Dentro do nosso statefulset, podes criar volumes dinamicamente para cada pod associado, usando volumeClaimTemplates, que será referenciado no nosso containers, via volumeMounts. Vej abaixo como fica:

statefulset.yaml
```
...
    spec:
      containers:
        - name: mysql
          image: mysql
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: root
          volumeMounts:
            - mountPath: /var/lib/mysql
              name: mysql-volume


  volumeClaimTemplates:
    - metadata:
        name: mysql-volume
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 5Gi
```

Criamos o volumeClaimTemplate mysql-volume, e dentro de volumeMounts, o referenciamos como volume dos pods desse container. Vamos agora aplicar e ver os efeitos:

```
fabiobione@DESKTOP-4KRU5T4:~/fullcycle/kubernetes$ kubectl apply -f k8s/statefulset.yaml
statefulset.apps/mysql created
fabiobione@DESKTOP-4KRU5T4:~/fullcycle/kubernetes$ kubectl get pods
NAME                        READY   STATUS    RESTARTS       AGE
goserver-749cb49946-hgd6c   1/1     Running   2 (128m ago)   20d
mysql-0                     1/1     Running   0              11m
mysql-1                     1/1     Running   0              11m
mysql-2                     1/1     Running   0              10m
mysql-3                     1/1     Running   0              10m
mysql-4                     1/1     Running   0              10m
fabiobione@DESKTOP-4KRU5T4:~/fullcycle/kubernetes$ kubectl get pvc
NAME                   STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
goserver-pvc           Bound    pvc-c50dadee-5248-4759-a7d7-6f01e1b6b051   5Gi        RWO            standard       20d
mysql-volume-mysql-0   Bound    pvc-6f5ddb93-df08-4621-b9c6-712710b94490   5Gi        RWO            standard       14m
mysql-volume-mysql-1   Bound    pvc-b03b8fb4-427b-4552-b602-612ef96372fb   5Gi        RWO            standard       14m
mysql-volume-mysql-2   Bound    pvc-e9c30387-7bd5-415a-8c7f-2c481a536747   5Gi        RWO            standard       13m
mysql-volume-mysql-3   Bound    pvc-188400d5-59f3-4ce2-a95a-978dcd4c02b9   5Gi        RWO            standard       13m
mysql-volume-mysql-4   Bound    pvc-fe3519cc-b0c0-4931-ac8f-8cc62016645b   5Gi        RWO            standard       13m
```

Podemos ver a criação de 5 pods, e também de 5 volumes montados, 1 para cada pod.


### Cert manager (TLS)

Para exemplificarmos, vamos criar o namespace cert-manager:

```
fabio@DESKTOP-34:~$ kubectl create namespace cert-manager

namespace/cert-manager created
```

Agora vamos seguir a instrução contida no [site de instrução.](https://cert-manager.io/docs/installation/kubectl/)

```
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
```

Após isso, podemos ver alguns pods criados pelo cert-manager:

```
fabio@DESKTOP-534:~$ kubectl get pods -n cert-manager
NAME                                       READY   STATUS              RESTARTS   AGE
cert-manager-7fb948f468-kt6c9              0/1     ContainerCreating   0          43s
cert-manager-cainjector-75c5fc965c-4lc74   1/1     Running             0          43s
cert-manager-webhook-757c9d4bb7-f7vrz      0/1     ContainerCreating   0          43s
```

Com o cert-manager instaldo, usaremos o objeto ClusterIssuer para criar o gerador de certificados: 

cluster-issuer.yml:
```
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
  namespace: cert-manager
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: fabiolopesbione@hotmail.com
    privateKeySecretRef:
      name: letsencrypt-tls
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx
```

Agora aplicaremos o arquivo:

```
kubectl apply -f k8s/cluster-issuer.yml
```

E pronto. Agora podemos em qualquer ingress informar esse issuer letsencrypt para gerar certificado tls para o domíniocom as seguintes annotations dentro do yml do ingress.

```
cert-manager.io/cluster-issuer: "letsencrypt"
```


### Conceito de namespaces

Namespaces são tags que categorizam um agrupamento (dev, prod, ...). Funciona como um agrupador lógico de objetos dentro do kubernetes.

```
kubectl apply -f deployment.yml -n=dev

fabio@DESKTOP-3243:~/fullcycle/kubernetes/k8s/namespaces$ kubectl get pods -n=dev
NAME                      READY   STATUS    RESTARTS   AGE
server-7c97dd76cc-btzwx   1/1     Running   0          3m17s
```

### Contextos por namespace

Um contexto define o cluster configurado para o kubernetes.

```
# Arquivo de configuração de contexto
cat ~/.kube/config
```

```
fabio@DESKTOP-5464:~/fullcycle/kubernetes/k8s/namespaces$ kubectl config current-context
kind-fullcycle
```

#### Criando contextos

Para criar contexto, devemos passar o namespace, cluster e o nome do usuário. Criaremos 2 contexts, dev e prod:

```
fabio@DESKTOP-54:~/fullcycle/kubernetes/k8s/namespaces$ kubectl config set-context dev --nam
espace=dev --cluster=kind-fullcycle --user=kind-fullcycle
Context "dev" created.
fabio@DESKTOP-54:~/fullcycle/kubernetes/k8s/namespaces$ kubectl config set-context prod --namespace=prod --cluster=kind-fullcycle --user=kind-fullcycle
Context "prod" created.
```

Agora, se olharmos as configurações em nosso kube, veremos o contexto que criamos no início, somado aos novos recém criados:

```
fabio@DESKTOP-543:~/fullcycle/kubernetes/k8s/namespaces$ kubectl config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://127.0.0.1:41553
  name: kind-fullcycle
contexts:
- context:
    cluster: kind-fullcycle
    namespace: dev
    user: kind-fullcycle
  name: dev
- context:
    cluster: kind-fullcycle
    user: kind-fullcycle
  name: kind-fullcycle
- context:
    cluster: kind-fullcycle
    namespace: prod
    user: kind-fullcycle
  name: prod
current-context: kind-fullcycle
kind: Config
preferences: {}
users:
- name: kind-fullcycle
  user:
    client-certificate-data: DATA+OMITTED
    client-key-data: DATA+OMITTED
```
Podemos mudar o contexto atual para dev, e assim conseguimos ver inclusive o pod ue criamos para o namespace dev, configurado para esse contexto:

```
fabio@DESKTOP-434:~/fullcycle/kubernetes/k8s/namespaces$ kubectl config use-context dev
Switched to context "dev".
fabio@DESKTOP-434:~/fullcycle/kubernetes/k8s/namespaces$ kubectl config current-context
dev
fabio@DESKTOP-434:~/fullcycle/kubernetes/k8s/namespaces$ kubectl get pods
NAME                      READY   STATUS    RESTARTS   AGE
server-7c97dd76cc-btzwx   1/1     Running   0          22m
```


### Service accounts
Dentro do kubernetes, o conceito de service account delimita o que um usuário tem permissão de fazer dentro de um cluster.

O service acount padrão é o default. Caso se crie objetos do kubernetes sem essa definição, estará no service account default, que não restringe em nada.

Vamos criar um serviceaccount, com role.

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: server

---

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: server-read
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "watch", "list"]
  
```

Podemos ver que criamos para o serviceaccount server a role server-read, com algumas regras de quem estiver com essa role, espeficicamente para pods, services e deployments. Agora vamos aplicar o arquivo criado.

security.yml
```
fabio@DESKTOP-43:~/fullcycle/kubernetes/k8s/namespaces$ kubectl apply -f security.yml
serviceaccount/server created
```
