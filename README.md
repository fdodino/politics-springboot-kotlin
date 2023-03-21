
# Spring Boot - Politics - Mapeo OR/M

[![build](https://github.com/uqbar-project/eg-politics-springboot-kotlin/actions/workflows/build.yml/badge.svg?branch=dockerize)](https://github.com/uqbar-project/eg-politics-springboot/actions/workflows/build.yml) [![codecov](https://codecov.io/gh/uqbar-project/eg-politics-springboot-kotlin/branch/master/graph/badge.svg)](https://codecov.io/gh/uqbar-project/eg-politics-springboot-kotlin)

## Prerrequisitos

Solo hace falta tener instalado Docker Desktop (el pack docker engine y docker compose), seguí las instrucciones de [esta página](https://phm.uqbar-project.org/material/software) en el párrafo `Docker`.


```bash
docker compose up
```

Eso levanta 

- PostgreSQL
- el cliente pgAdmin, como está explicado en [este ejemplo](https://github.com/uqbar-project/eg-manejo-proyectos-sql)
- y también **la app Politics escrita en Spring Boot**

## Conexión a la base

La conexión a la base se configura en el archivo [`application-local.yml`](./src/main/resources/application-local.yml):

```yml
spring:
  #   base de datos posta
  datasource:
    url: jdbc:postgresql://politics_sql:5432/politics
```

El archivo Dockerfile que tiene como entrypoint el siguiente comando:

```Dockerfile
# Levantamos el main de Spring Boot
CMD ./gradlew clean bootRun
```

que es el que permite levantar por consola nuestro main.

## Cómo hacer el deploy

```bash
docker build -t politics-exe .
```

Lo podemos probar localmente:

```bash
docker run politics-exe
```

## Deploy en Render

Se hace ingresando al dashboard de [render](render.io)



