# fullcycle
Anotações sobre aprendizado do bootcamp fullcycle developer


# Docker
### Criação de container docker
Para criar um container docker, precisamos referenciar o comando *docker run {{imagem}}*, onde a imagem precisa estar hospedada em um hub, por default, temos o docker hub

`docker run hello-world` 

A saída será a seguinte:

`Hello from Docker!`

Após isso, o container para, porque não tem nenhum comando que mantenha ele rodando. Isso poderá ser observado através do comando abaixo:

`docker ps`

Não irá listar o container criado sobre a imagem do hello-world, a nã ser que execute com a flag -a:

`docker ps -a`

### Porta disponível
Ao subir um container, por mais que ele tenha uma porta padrão liberada, como é o caso por exemplo do nginx, ao acessar localhost:80, não será acessado. Isso se dá porquê as portas só serão liberadas internamente na rede docker, Porém, podemos fazer um bind para externalizar a porta, com a configuração -p, abaixo:

`docker run --name nginx -p 8080:80 nginx`

Com isso, conseguimos acessar via localhost:8080, visto que mapeamento a porta interna 80 para a externa 8080.

### Volumes
Containers criados através de imagens docker são imutáveis, obtendo um espaço para escrita. Porém, se removermos o o container, os dados salvos também serão apagados. Resolvemos isso com o conceito de volume, onde mapeamos uma pasta do container com uma pasta na nossa máquina. Dessa forma, as alterações locais refletem no container, e se apagarmos o container, mantemos esses dados da pasta. Usamos a flag *-v* com o mapeamento desejado:

`docker run --name nginx -p 8080:80 nginx -v ~/html:/usr/share/nginx/html`

### Mount
Assim como o volume, o comando *--mount* mapeia um diretório que compartilha os dados com outro diretório do container, como se vê a aplicação abaixo:

`docker run --name nginx -p 8080:80 --mount type=bind,source=~/html,target=/usr/share/nginx/html nginx`

### Exclusão
Para excluir um container, executamos o comando docker rm, informando o id ou o nome, que pode ser visto em *docker ps* ou *docker ps -a*, conforme abaixo:

`docker rm {{id_container || nome_container}}`

#### Anotações push do git

Desde setembro de 2021 não é mais aceito dentro do github submeter push via login/senha. Temos que cadastrar um token dentro do github, para após isso, executar o comando abaixo:

`git remote set-url origin https://[colar aqui o token gerado]@github.com/[repositorio]`


### Criação de imagem utilizando Dockerfile
Dentro de um arquivo chamado Dockerfile, podemos definir uma imagem fonte e personalizações baseadas nas imagens selecionadas. Vejamos o conteúdo abaixo de um dockerfile:

`FROM nginx:latest`
`RUN apt-get update`
`RUN apt-get install vim -y`

No conteúdo, estamos solicitando que seja instaldo dentro da imagem base do nginx o vim.

`docker build -t fabiobione/nginx-com-vim:latest ./path_do_Dockerfile`

Isso irá construir uma imagem docker de nome **fabiobione/nginx-com-vim** com a tag **latest** no caminho designado após esses dados. Ao executar.

### Aprofundando o Dockerfile
Vamos analisar o seguinte conteúdo:

`FROM nginx:latest`  
`WORKDIR /app`  
`RUN apt-get update && \`  
`apt-get install vim -y`  
`COPY html /usr/share/nginx/html`  

O comando **WORKDIR** define um diretório no container que será a pasta home. Dentro so **RUN** pode ser visto comandos encadeados pela notação 
*&& \\* . **COPY** irá copiar algo de fora do container para dentro. Se após docker build dessa imagem, entrarmos no container, iremos ver o conteúdo da pasta externa html dentro do container, executando o seguinte:

`docker run -it fabiobione/nginx-com-vim bash`  
Dentro da pasta *app* no container:  
`cat /usr/share/nginx/html/index.html`

### CMD e ENTRYPOINT

`Observe o Dockerfile abaixo:`  
`FROM ubuntu:latest`  
`ENTRYPOINT ["echo", "Hello "]`  
`CMD ["World"]`  

CMD define qualquer execução dentro de um terminal dento do container.

O ENTRYPOINT é o comando de entrada que será executado ao subir o container. No exemplo acima, o cmd adicionará entrada de dados ao comando executado no ENTRYPOINT, no caso, *echo Hello world*. Podemos mudar inserir comandos ao entrypoint ao fazer a execuçã do container, como segue abaixo:

`docker run --rm fabiobione/hello Bione`  

Nesse caso, o comando executado pelo ENTRYPOINT será *echo Hello Bione*
