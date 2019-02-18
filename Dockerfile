# Apollo
FROM tomcat:8.5-jre8-alpine

COPY build.sh /bin/build.sh
ENV WEBAPOLLO_VERSION e7adf9392699caa317898391d79d09bbd399f8e8
ADD apollo-config.groovy /apollo/apollo-config.groovy

ENV CONTEXT_PATH ROOT

RUN apk update && \
	apk add --update tar && \
	apk add curl ca-certificates bash nodejs git postgresql-client maven libpng \
		make g++ zlib-dev expat-dev nodejs-npm sudo openssh-client perl zip gradle yarn && \
	npm install -g bower && \
	adduser -s /bin/bash -D -h /apollo apollo && \
	curl -L https://github.com/GMOD/Apollo/archive/${WEBAPOLLO_VERSION}.tar.gz | \
	tar xzf - --strip-components=1 -C /apollo && \
	chown -R apollo:apollo /apollo && \
	apk add openjdk8 openjdk8-jre && \
	cp /usr/lib/jvm/java-1.8-openjdk/lib/tools.jar /usr/lib/jvm/java-1.8-openjdk/jre/lib/ext/tools.jar && \
	curl -s get.sdkman.io | sudo -u apollo /bin/bash && \
	sudo -u apollo /bin/bash -c "source /apollo/.sdkman/bin/sdkman-init.sh && yes | sdk install grails 2.5.5" && \
	sudo -u apollo /bin/build.sh && \
	rm -rf ${CATALINA_HOME}/webapps/* && \
    cp /apollo/apollo.war ${CATALINA_HOME}/webapps/${CONTEXT_PATH}.war && \
    mkdir ${CATALINA_HOME}/webapps/${CONTEXT_PATH} && \
    cd ${CATALINA_HOME}/webapps/${CONTEXT_PATH} && \
    jar xvf ../${CONTEXT_PATH}.war && \
	rm -rf ${CATALINA_HOME}/webapps/${CONTEXT_PATH}.war && \
	apk del curl nodejs git make g++ nodejs-npm openjdk8 sudo gradle yarn

RUN apk add py3-numpy build-base python3-dev && \
    pip3 install apollo && \
	apk del build-base python3-dev

ADD canned_comments.txt canned_keys.txt canned_status.txt /bootstrap/
ADD bootstrap.sh /bootstrap.sh

ADD launch.sh /launch.sh

CMD "/launch.sh"
