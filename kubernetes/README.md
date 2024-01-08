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