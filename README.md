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