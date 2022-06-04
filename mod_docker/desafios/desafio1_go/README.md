# Desafio 1 docker

## Desafio Go

Esse desafio é muito empolgante principalmente se você nunca trabalhou com a linguagem Go!
Você terá que publicar uma imagem no docker hub. Quando executarmos:

docker run <seu-user>/codeeducation

Temos que ter o seguinte resultado: Fullcycle Rocks!

Se você perceber, essa imagem apenas realiza um print da mensagem como resultado final, logo, vale a pena dar uma conferida no próprio site da Go Lang para aprender como fazer um "olá mundo".

Lembrando que a Go Lang possui imagens oficiais prontas, vale a pena consultar o Docker Hub.

3) A imagem de nosso projeto Go precisa ter menos de 2MB =)

Dica: No vídeo de introdução sobre o Docker quando falamos sobre o sistema de arquivos em camadas, apresento uma imagem "raiz", talvez seja uma boa utilizá-la.

Divirta-se

## Passos de implementação

Como a proposta visa apenas imprimir na tela o texto e depois concluir a execução, seria apenas necessário criar um arquivo *main.go*, com o comando de print. esse arquivo pode ser visto [aqui.](https://github.com/fabiolopes/fullcycle/blob/main/mod_docker/desafios/desafio1_go/main.go)  

Com o arquivo go implementado, precisamos de um build com menos de 2MB. A imagem principal de go é bem maior que isso. Então a solução é usar uma imagem go, dar o comando de compliação, e após isso, copiar isso para uma imagem enxuta scratch, e dar o comando de execução. Veja o [Dockerfile.](https://github.com/fabiolopes/fullcycle/blob/main/mod_docker/desafios/desafio1_go/Dockerfile)

Com a essa estrutura pronta, o docker-compose precisa apenas fazer o build do Dockerfile, e após o comando *docker-compose up*, o script será executado.

Tendo feito isso, haverá uma imagem criada a partir dessa estrutura executada, então daremos o comando de push para o docker hub.

### Comandos
Execute o comando *docker-compose up*. Após isso, será impresso no console o texto "Fullcycle rocks".
Repositório da imagem no docker hub: [golang_app.](https://hub.docker.com/repository/docker/fabiobione/golang_app)
