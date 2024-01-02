# Desafio 2 docker

## Nginx com Node.js

Nesse desafio você colocará em prática o que aprendemos em relação a utilização do nginx como proxy reverso. A idéia principal é que quando um usuário acesse o nginx, o mesmo fará uma chamada em nossa aplicação node.js. Essa aplicação por sua vez adicionará um registro em nosso banco de dados mysql, cadastrando um nome na tabela people.

O retorno da aplicação node.js para o nginx deverá ser:

<h1>Full Cycle Rocks!</h1>

- Lista de nomes cadastrada no banco de dados.

Gere o docker-compose de uma forma que basta apenas rodarmos: docker-compose up -d que tudo deverá estar funcionando e disponível na porta: 8080.

Suba tudo em um repositório e faça a entrega.

## Passos de implementação

Trata-se de uma proposta mais complexa. Precisamos subir 3 containeres: node, mysql e nginx. Sendo que a instância do nginx depende diretamente do app node, e a aplicação node não pode começar a ser executado antes do mysql, visto que o comando principal na execução da página e ir no banco, salvar um novo nome e apresentar a lista de nomes existentes no banco.

Algumas características importantes para lembrar:

- Para o app aguardar a subida do banco, usaremos dockerize;
- Normalmente para bancos de dados usamos um volume próprio para que os dados persistam, mesmo recriando o container. Como esse não é o foco, foi criado volume apenas para o arquivo de inicialização do banco (init.sql;)
- A porta padrão do nginx é 80;


### Configurações do mysql

Por padrão, já é criado pelo container um usuário root, então apenas precisamos definir um password, como podevos ver na variável *MYSQL_ROOT_PASSWORD*.
A criação da base e da tabela que utilizaremos é feita através do comando *--init-file /data/application/init.sql*. Esse caminho será encontrado porque definimos esse arquivo via volume, conforme docker-compose.yml da raíz.

### Configurações de app (node)

O container será criado via Dockerfile. Usando uma imagem node, instalamos o wget, pois ele será necessário para baixar o dockerize. Após isso, é feita uma exposição da porta 3000.

No *docker-compose.yml* usamos como entrypoint comandos para o dockerize aguardar a subida de db, combinando comando do docker-entrypoint.sh, e executamos os comandos de npm install, que baixa as dependências do projeto, e node index.js. No arquivo de index, temos 3 dependências: express, mysql e node-random-name. Para não ter que executar o npm install de cada uma dessas dependências, optei por criar o projeto e instalar essas libs localmente, no intuito de gerar os arquivos package.json e package-lock.json. Dessa forma, a simples execução do npm install já deixa o projeto pronto.


### Configurações do nginx

Usando uma imagem aenxuta do nginx, copiamos para dentro do container o nginx.conf que contém a rota onde, quando for solicitado localhost:80, haverá um redirecionamento dessa requisição para localhost:3000, batendo internamente na aplicação app. Cria-se um arquivo index.php apenas para não dar erro interno do nginx.

No Dockerfile, exponho a porta 8080 para bater internamente na porta do nginx (80).


### Comandos
Execute o comando *docker-compose up*. Via comando *docker logs -f app*, acompanhe o momento em que o app consegue se comunicar com db:3306. Após isso, ao digitar no browser localhost:8080, será adicionado um nome aleatório, gerado pela lib node-random-name, e será apresentada uma lista com todos os nomes cadastrados na base até então.