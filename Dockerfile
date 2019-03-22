# Apollo
FROM tomcat:8.5-jre8-alpine

COPY build.sh /bin/build.sh
ENV WEBAPOLLO_VERSION df779aad1fcdfac2a461488d92ab2c191e993c3a
ADD apollo-config.groovy /apollo/apollo-config.groovy

ENV CONTEXT_PATH ROOT

# Temp patch until https://github.com/GMOD/Apollo/pull/2068 is merged
ADD 2068.diff /tmp/2068.diff
ADD 2070.diff /tmp/2070.diff
ADD 2097.diff /tmp/2097.diff
ADD 2098.diff /tmp/2098.diff
ADD 2100.diff /tmp/2100.diff

RUN apk update && \
	apk add --update tar && \
	apk add curl ca-certificates bash nodejs git postgresql-client maven libpng wget \
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
	apk del curl nodejs git make g++ nodejs-npm openjdk8 sudo gradle yarn && \
	rm /tmp/2068.diff /tmp/2070.diff /tmp/2097.diff /tmp/2098.diff /tmp/2100.diff

RUN apk add py3-numpy build-base python3-dev && \
    pip3 install apollo && \
	apk del build-base python3-dev

# This is to fix problems with mounted blat failing to run as it depends on some glibc things
# Safe to remove if not using blat
# Borrowed from https://github.com/jeanblanchard/docker-alpine-glibc/blob/master/Dockerfile
ENV GLIBC_VERSION 2.29-r0
RUN apk add --update curl && \
	curl -Lo /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
	curl -Lo glibc.apk "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk" && \
	curl -Lo glibc-bin.apk "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk" && \
	apk add glibc-bin.apk glibc.apk && \
	/usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib && \
	apk del curl && \
	rm -rf glibc.apk glibc-bin.apk /var/cache/apk/*

ADD canned_comments.txt canned_keys.txt canned_status.txt /bootstrap/
ADD bootstrap.sh /bootstrap.sh

ADD launch.sh /launch.sh

CMD "/launch.sh"
