####
# This Dockerfile is used in order to build a container that runs the Quarkus application in JVM mode
#
# Build the image with:
#
# docker build -f src/main/docker/Dockerfile.jvm.staged -t quarkus/code-with-quarkus-jvm .
#
# Then run the container using:
#
# docker run -i --rm -p 8081:8081 quarkus/code-with-quarkus-jvm
#
# If you want to include the debug port into your docker image
# you will have to expose the debug port (default 5005) like this :  EXPOSE 8080 5050
#
# Then run the container using :
#
# docker run -i --rm -p 8081:8081 -p 5005:5005 -e JAVA_ENABLE_DEBUG="true" quarkus/code-with-quarkus-jvm
#
###
FROM registry.access.redhat.com/ubi8/openjdk-11:latest

USER root
WORKDIR /build
RUN mkdir -p .mvn/wrapper
# Build dependency offline to streamline build
COPY mvnw* .
COPY .mvn/wrapper .mvn/wrapper
COPY pom.xml .
RUN ./mvnw dependency:go-offline

COPY src src
RUN ./mvnw package

FROM registry.access.redhat.com/ubi8/openjdk-11-runtime:1.10

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en'

# Configure the JAVA_OPTIONS, you can add -XshowSettings:vm to also display the heap size.
ENV JAVA_OPTIONS="-Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager"

# We make four distinct layers so if there are application changes the library layers can be re-used
COPY --from=0 --chown=1001 /build/target/quarkus-app/lib/ /deployments/lib/
COPY --from=0 --chown=1001 /build/target/quarkus-app/*.jar /deployments/
COPY --from=0 --chown=1001 /build/target/quarkus-app/app/ /deployments/app/
COPY --from=0 --chown=1001 /build/target/quarkus-app/quarkus/ /deployments/quarkus/

EXPOSE 8080
USER 185

ENTRYPOINT [ "java", "-jar", "/deployments/quarkus-run.jar" ]
