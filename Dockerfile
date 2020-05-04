# Apollo
FROM tomcat:8.5-jre8-alpine

COPY build.sh /bin/build.sh
ENV WEBAPOLLO_VERSION b8755f6e19935d16e83d88d16ce611f373e3bc4c
ADD apollo-config.groovy /apollo/apollo-config.groovy

# Dir where uploaded jbrowse data will be stored
VOLUME ["/apollo-data-local/"]
ENV WEBAPOLLO_COMMON_DATA /apollo-data-local/

ENV CONTEXT_PATH ROOT

# Temp Apollo patches when needed...
ADD 2379.diff /tmp/2379.diff
ADD 90b893d8d68afcf46711a9ce0f2fd8109e178ae2.diff /tmp/90b893d8d68afcf46711a9ce0f2fd8109e178ae2.diff
ADD 6ef7007c3c21c397704563bc8b0529dd260360da.diff /tmp/6ef7007c3c21c397704563bc8b0529dd260360da.diff
ADD symlink_fix.diff /tmp/symlink_fix.diff
ADD 2476.diff /tmp/2476.diff

RUN apk update && \
	apk add --update tar && \
	apk add curl ca-certificates bash nodejs git postgresql-client maven libpng wget \
		make g++ zlib-dev expat-dev nodejs-npm sudo openssh-client perl zip gradle yarn && \
	npm config set unsafe-perm true && \
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
	rm -f /tmp/*.diff

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
