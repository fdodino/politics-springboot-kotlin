
# Spring Boot - Politics - Mapeo OR/M

[![build](https://github.com/uqbar-project/eg-politics-springboot-kotlin/actions/workflows/build.yml/badge.svg?branch=dockerize)](https://github.com/uqbar-project/eg-politics-springboot/actions/workflows/build.yml) [![codecov](https://codecov.io/gh/uqbar-project/eg-politics-springboot-kotlin/branch/master/graph/badge.svg)](https://codecov.io/gh/uqbar-project/eg-politics-springboot-kotlin)

## Levantando la instancia de Postgres en la nube

Utilizaremos [render](https://render.com/) como servicio de hosting para levantar una instancia de nuestra base de datos Postgres. Lo hacemos de la siguiente manera:

- Creamos una cuenta de uso gratuito en Render (podemos utilizar nuestro usuario de github)
- Ingresamos a la página de [dashboard de Render](https://dashboard.render.com/)
- En la barra de menú seleccionamos New > PostgreSQL

![render new](./images/render-01-new.png)

![render postgresql](./images/render-02-postgresql.png)

En la ventana de creación indicamos el nombre (en este caso `politics-data`), en database podemos escribir `politics_data` y en usuario `admin` (o dejar que autogenere nombres)

![render postgres definition](./images/render-03-postgresql-definition.png)

y por último vemos el disclaimer de que no tendremos backup y la base se mantendrá solo por 90 días, y presionamos el botón `Create Database`.

![render create database](./images/render-04-free-database.png)

> Un detalle importante es que solo se permite una base de datos para los planes Free, si te aparece el mensaje `Error: cannot have more than one active free tier database` podés definir un origen de datos que tenga un nombre más general

Una vez creado te aparece el panel para ver la información de la base creada, así como el string de conexión:

![render connection](./images/render-05-connection.gif)

Copiamos los datos del string de conexión para utilizarlos en el archivo `application.yml`.

## Configurando la conexión a la base en Springboot

El string de conexión viene como `postgres://--USUARIO--:--PASSWORD--@--HOST--/--DATABASE_NAME--`, nosotros vamos a discriminar la información de la siguiente manera:

```yml
spring:
  # base de datos en la nube -> Render
  datasource:
    url: jdbc:postgresql://dpg-cgfisc82qv28tc7qhip0-a.oregon-postgres.render.com:5432/politics_data
    username: admin
    password: Z0503SXaQos82oFS3XDwguVweHorSPxT
    driver-class-name: org.postgresql.Driver
```

Podemos levantar la app desde el IDE para probar que funciona correctamente:

```bash
Zona Springfield creada
------------------------------------------------------------------------
2023-03-25T14:41:31.499-03:00  INFO 351103 --- [  restartedMain] o.s.b.d.a.OptionalLiveReloadServer       : LiveReload server is running on port 35729
2023-03-25T14:41:31.517-03:00  INFO 351103 --- [  restartedMain] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path ''
2023-03-25T14:41:31.523-03:00  INFO 351103 --- [  restartedMain] o.uqbar.politics.PoliticsApplicationKt   : Started PoliticsApplicationKt in 32.108 seconds (process running for 32.451)
```

Hacemos la consulta desde Insomnia y ya estamos utilizando una app local con una base de datos en la nube:

![todas las zonas - local - base de datos en la nube](./images/insomnia-zonas-local-contra-bd-nube.png)

![deploy fase 1](./images/deploy-arquitectura-fase-1.png)

A continuación vamos a trabajar sobre nuestra aplicación Politics de Springboot.

## Dockerfile para levantar la app

Dado que queremos desplegar la aplicación en un contenedor Docker, las opciones que tenemos son:

- pedirle a gradle que empaquete nuestro código y levante el Tomcat con el archivo generado, lo que sería ejecutar el comando `./gradlew bootRun`. Esta es la opción más directa pero tuvimos inconvenientes con algunos servicios de hosting como Render, donde el deploy directamente se colgaba y fallaba sin mostrar ningún mensaje de error
- o resolver la tarea en dos pasos: primero empaquetar el código y luego pedirle manualmente a Java que levante el código empaquetado

A continuación vamos a explicar esta idea.

### Empaquetando nuestra app

Para entender lo que sucederá en nuestro archivo `Dockerfile` vamos a hacer exactamente lo mismo pero dentro del IDE. Para lo cual abrimos la solapa Gradle (lo podés encontrar como `Gradle` a la derecha o bien un ícono), y en el agrupador `build` podés seleccionar `bootJar`:

![bootJar](./images/bootJar.gif)

Gradle compila los archivos `.kt` y genera el bytecode en archivos `.class` correspondientes dentro de la siguiente estructura:

```bash
+ build
  + classes
    + kotlin
      + main
        + org
          + uqbar
            + politics
              - PoliticsApplication (compilado)
              - PoliticsApplicationKt.class
              - PoliticsBootstrap (compilado)
              + controller
                - CandidateController (compilado)
                ...
```

Pero además, comprime todas estas definiciones en un archivo zip cuya extensión es en realidad **jar** (por **J**ava **Ar**chive).

El jar lo podés ver en el directorio `build/libs`. Es posible que veas más de un JAR

- `politics-springboot-kotlin-0.0.1-SNAPSHOT.jar`
- `politics-springboot-kotlin-0.0.1-SNAPSHOT-plain.jar`

Tenés muchas variantes para empaquetar archivos, te dejamos este gráfico que muestra las alternativas:

![variantes de jar](./images/packaging-jar.png)

- **Fat jar**: la tarea `bootJar` genera la versión que te permite ejecutarlo mediante la instrucción `java -jar`. Contiene **todo lo que necesitás para ejecutar la aplicación**, eso implica tener todas tus clases y además las dependencias. Dentro del gráfico es la variante **fat/uber**.
- **Plain jar**: la tarea `jar` de Gradle genera una variante más chica, que solo tiene el conjunto de clases desarrolladas por nosotros en el proyecto. Dentro del gráfico es la variante **skinny**.

Si te interesa conocer cómo podés empaquetar otras variantes, te dejamos el link [a la documentación de Gradle](https://docs.spring.io/spring-boot/docs/2.5.1/gradle-plugin/reference/htmlsingle/#packaging-executable.and-plain-archives).

Te mostramos a continuación cómo ejecutar `gradle bootJar` desde el IDE:

![gradle bootjar](./images/docker-01-bootjar.gif)

### Ejecutando la app desde la línea de comando

Desde Powershell, o bien desde la terminal podés ejecutar el archivo `jar` (no el `plain` sino el `fat`):

```bash
java -jar build/libs/politics-springboot-kotlin-0.0.1-SNAPSHOT.jar
```

Eso permite que levante el application server Tomcat:

```
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::                (v3.0.2)

2023-03-24T14:29:04.814-03:00  INFO 319667 --- [           main] o.uqbar.politics.PoliticsApplicationKt   : Starting PoliticsApplicationKt using Java 17.0.5 with PID 319667 (/home/dodain/workspace/phm-2023/politics-springboot-kotlin/build/libs/eg-politics-springboot-kotlin-0.0.1-SNAPSHOT.jar started by dodain in /home/dodain/workspace/phm-2023/politics-springboot-kotlin)
2023-03-24T14:29:04.816-03:00  INFO 319667 --- [           main] o.uqbar.politics.PoliticsApplicationKt   : No active profile set, falling back to 1 default profile: "default"
2023-03-24T14:29:04.866-03:00  INFO 319667 --- [           main] .e.DevToolsPropertyDefaultsPostProcessor : For additional web related logging consider setting the 'logging.level.web' property to 'DEBUG'
...
```

Ya podés acceder a los endpoints desde Insomnia, POSTMAN o cualquier cliente REST.

Te dejamos el gif que ilustra el proceso:


![docker java jar](./images/docker-02-java-jar.gif)

Volvemos a ejecutar en Insomnia (o POSTMAN) la búsqueda de zonas:

![zonas insomnia](./images/insomnia-zonas-local-contra-bd-nube.png)

Veamos los cambios en nuestra arquitectura:

![deploy fase 2](./images/deploy-arquitectura-fase-2.png)

### Implementando el container de Docker

### Definición del Dockerfile

Veamos cómo se configura el `Dockerfile`:

```Dockerfile
# aplicación Politics en spring boot app
FROM gradle:7.5.1-jdk17-focal AS build
COPY --chown=gradle:gradle . /home/gradle/src
ADD . /home/gradle/src
WORKDIR /home/gradle/src
RUN gradle bootJar --no-daemon

# ejecutamos el JAR resultante
FROM amazoncorretto:17.0.5
EXPOSE 8080
COPY --from=build /home/gradle/src/build/libs/politics-springboot-kotlin-0.0.1-SNAPSHOT.jar /app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]
```

En este caso estamos automatizando el proceso de

- compilación/empaquetado, a cargo de gradle
- y la ejecución del **fat jar** mediante el comando `java -jar /app.jar`

Hay que tener en cuenta que no estamos utilizando el wrapper de gradle que está en nuestro proyecto, con lo cual hay que mantener sincronizadas la versión local de nuestro proyecto Springboot y la imagen que utilizamos en nuestro Dockerfile (en este caso es la 7.5.1).
> TODO: El approach de generar Fat Jar no es la mejor opción para Docker . Generar un fat JAR tiene la contra de que el archivo es pesado y además consume tiempo empaquetar todas las dependencias. Como sugiere [este artículo](https://phauer.com/2019/no-fat-jar-in-docker-image/) podemos pensar como alternativa en trabajar únicamente con un plain jar y tener pre-armada la opción hollow en una capa previa. Lo dejaremos para una segunda iteración.

### Generando la imagen y el contenedor

Para construir la imagen vamos a partir del archivo `Dockerfile` y le vamos a poner como tag `politics-exe`:

```bash
docker build -t politics-exe .
```

Podemos comprobar que la imagen fue correctamente creada:

```bash
docker images | grep politics-exe
```

Lo que nos debería devolver un output similar a éste:

```
politics-exe                             latest               90a9eeadec44   12 hours ago    521MB
```

Levantamos el contenedor

```bash
docker run -p 8080:8080 --name politics-app politics-exe
```

En otra terminal verificamos que esté correctamente levantado:

```bash
docker ps -a | grep politics-exe
```

debería decirnos que está levantado:

```
c6af879ba638   politics-exe                            "java -jar /app.jar"     4 minutes ago   Up 4 minutes               0.0.0.0:8080->8080/tcp, :::8080->8080/tcp   politics-app
```

y lo probamos nuevamente en nuestro cliente REST:

![insomnia prueba](./images/insomnia-zonas-local-contra-bd-nube.png)

Dejamos el resumen de la arquitectura de este tercer approach:

![arquitectura dockerfile local](./images/deploy-arquitectura-fase-3.png)

## Deploy en Railway

Ahora que sabemos que la imagen funciona para un contenedor local, vamos a desplegarlo (deployarlo) en la nube.

[Railway](https://railway.app/) nos ofrece la posibilidad de hostear diferentes tipos de aplicación, podés consultar [los diferentes planes que tiene](https://railway.app/pricing). Al momento de escribir el README podemos utilizar 500 horas o u$s 5.00 **por mes** que se van renovando. La buena noticia es que en el [dashboard](https://railway.app/dashboard) te avisa en todo momento cuántas horas y u$s utilizaste:

![railway dashboard trial](./images/railway-dashboard-trial.png)

La forma de publicar la aplicación es realmente sencilla:

- ingresá con tu cuenta de github
- en el Dashboard tenés un botón New, que abre una serie de opciones
- elegís `Github Repo`
- la primera vez tenés que agregar permisos a Railway para que pueda encontrar los repositorios de tu organización o usuario:

![Railway - Github app permissions](./images/railway-01-github-app-permissions.gif)

Aceptás darle acceso a dichos repositorios y a continuación te aparecerán en la lista para poder hacer el deploy.

- seleccionás el repositorio que quieras deployar
- y ¡listo! automáticamente se inicia el deploy
- es necesario configurar en una variable cuál es el puerto donde va a estar escuchando pedidos nuestra aplicación, para eso hacemos click sobre la aplicación `politics-springboot-kotlin`, solapa Variables, New Variable > `PORT` es el VARIABLE_NAME y `8080` el VALUE
- en Settings podés ver otras configuraciones como
  - qué rama asociada genera automáticamente un deploy con cada push (por defecto `master` o `main`)
  - la opción `Check suites` que permite esperar a que pase el CI antes de hacer el deploy (**algo recomendable**)
  - el dominio que te va a permitir construir la URL para hacer pedidos, ya sea desde la app React o via Insomnia
  - y otras opciones

![railway settings](./images/railway-02-variables-settings.gif)

Cuando termine de levantarse el contenedor se verá reflejado en nuestro dashboard:





