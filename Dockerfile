# aplicación Politics en spring boot app
FROM gradle:7.5.1-jdk17-focal AS build
COPY --chown=gradle:gradle . /home/gradle/src
ADD . /home/gradle/src
WORKDIR /home/gradle/src
RUN gradle bootJar --no-daemon

# ejecutamos el JAR resultante
FROM amazoncorretto:17.0.5
EXPOSE 8080
COPY --from=build /home/gradle/src/build/libs/eg-politics-springboot-kotlin-0.0.1-SNAPSHOT.jar /app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]
