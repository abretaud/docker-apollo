# WebApollo
# VERSION 2.0
FROM ubuntu:16.10
MAINTAINER Eric Rasche <esr@tamu.edu>, Nathan Dunn <nathandunn@lbl.gov>
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update --fix-missing && \
	apt-get --no-install-recommends -y install \
	git build-essential maven libpq-dev postgresql-common tomcat8 openjdk-8-jdk nodejs npm wget \
	postgresql postgresql-client xmlstarlet netcat  \
	zlib1g-dev libexpat1-dev ant curl ssl-cert && \
	apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
#    apt-get -qq update --fix-missing && \
#	apt-get --no-install-recommends -y install \
#	openjdk-8 nodejs    && \

RUN ln -s /usr/bin/nodejs /usr/bin/node && \
	npm install -g bower && \
	cp /usr/lib/jvm/java-8-openjdk-amd64/lib/tools.jar /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/ext/tools.jar && \
	useradd -ms /bin/bash -d /apollo apollo

# RUN cpan notest install Text::Markdown  # needed for apollo release
ENV WEBAPOLLO_VERSION ba55496a9b4ee3848f3699c08706f2617a10621a
RUN curl -L https://github.com/GMOD/Apollo/archive/${WEBAPOLLO_VERSION}.tar.gz | tar xzf - --strip-components=1 -C /apollo


# RUN cpan notest install Text::Markdown  # needed for apollo release

ADD Config.groovy /apollo/grails-app/conf/Config.groovy

COPY build.sh /bin/build.sh
ADD apollo-config.groovy /apollo/apollo-config.groovy

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
RUN chown -R apollo:apollo /apollo
USER apollo
RUN bash /bin/build.sh
USER root

ENV CONTEXT_PATH ROOT
ENV CATALINA_HOME /var/lib/tomcat8

RUN rm -rf ${CATALINA_HOME}/webapps/*

# Download chado schema
RUN wget --quiet https://github.com/erasche/chado-schema-builder/releases/download/1.31-jenkins97/chado-1.31.sql.gz -O /chado.sql.gz && \
	gunzip /chado.sql.gz
ADD user.sql /apollo/user.sql

ADD launch.sh /launch.sh
CMD "/launch.sh"
