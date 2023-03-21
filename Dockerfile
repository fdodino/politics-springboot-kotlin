# base de datos PostgreSQL
#FROM postgres:15-alpine
#ENV POSTGRES_USER postgres
#ENV POSTGRES_PASSWORD postgres
#ENV POSTGRES_DB politics_sql
#COPY ./Docker/init_db.sh /docker-entrypoint-initdb.d/01_init_db.sh

# aplicación Politics en spring boot app
FROM gradle:7.5.1-jdk17-focal AS build
#VOLUME gradle-cache:/home/gradle/.gradle
COPY --chown=gradle:gradle . /home/gradle/src
ADD . /home/gradle/src
WORKDIR /home/gradle/src
RUN gradle bootJar --no-daemon

# ejecutamos el JAR resultante
FROM amazoncorretto:17.0.5
EXPOSE 8080
COPY --from=build /home/gradle/src/build/libs/eg-politics-springboot-kotlin-0.0.1-SNAPSHOT.jar /app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]

# Se buildea con
# docker build . -t politics-exe

# Se ejecuta con
# docker run politics-exe
