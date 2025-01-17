FROM hub.docker.hpecorp.net/hub/openjdk:8-jdk-alpine

## Create a new user group ##
RUN addgroup docker

## Create a new non-root application user and add it to newly created group ##
ARG USER=$appuser
ARG PASS=$password
ARG USER_ID=$userid
ARG BUILD_ENV=$buildEnv
RUN adduser -D $USER -u $USER_ID -G docker && echo "$USER:$PASS" | chpasswd

## Switch to application user and copy application jar ##
USER $USER
COPY target/*.jar app.jar
## Switch back to root user to load GTS and IAM certificates to keystore ##
USER root
VOLUME /logs

COPY GTS-$BUILD_ENV-cert.crt $JAVA_HOME/jre/lib/security
COPY java.security $JAVA_HOME/jre/lib/security
RUN cd $JAVA_HOME/jre/lib/security
RUN mkdir /etc/security
COPY sslciphers.conf /etc/security
RUN keytool -keystore $JAVA_HOME/jre/lib/security/cacerts -storepass changeit -noprompt -trustcacerts -importcert -alias gtsws3 -file $JAVA_HOME/jre/lib/security/GTS-$BUILD_ENV-cert.crt

## Set New Relic Configuration Items ##
RUN mkdir/local/container/newrelic/logs
ADD ./newrelic/nr -p /usewrelic.jar /usr/local/container/newrelic/newrelic.jar
ENV JAVA_OPTS="$JAVA_OPTS -javaagent:/usr/local/container/newrelic/newrelic.jar"
ADD ./newrelic/newrelic.yml /usr/local/container/newrelic/newrelic.yml
ENV JAVA_OPTS="$JAVA_OPTS -Dnewrelic.config.license_key='bea848dde8ab41e5f07794fc58f77a3ee5a3NRAL'"
ENV JAVA_OPTS=-Dnewrelic.config.log_file_name=STDOUT

## Set necessary permissions to application and new relic folders ##
RUN chown $USER:docker /app.jar
RUN chown -R $USER:docker /usr/local/container
RUN mkdir -p /opt/cloudhost/logs/PPSlogging
RUN chown -R $USER:docker /opt/cloudhost/logs/PPSlogging

## Switch to application user before starting application##
USER $USER

EXPOSE 9201

ENTRYPOINT java -javaagent:/usr/local/container/newrelic/newrelic.jar -Dnewrelic.environment=$deployEnv -jar /app.jar

#ENTRYPOINT ["java", "-Djavax.net.debug=ssl:handshake:verbose", "-jar", "/app.jar"]

# To run your container locally execute this commands
# docker build -t globaltradegateway .
# docker run -it -e "deployEnv=dev" --name globaltradegateway-c -p 9202:9202 -v c:/docker/logs:/logs -d globaltradegateway
# docker logs -f globaltradegateway-c
