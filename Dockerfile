# Apollo
# VERSION 2.1.0
FROM tomcat:8-jre8
MAINTAINER Anthony Bretaudeau <anthony.bretaudeau@inra.fr>, Eric Rasche <esr@tamu.edu>, Nathan Dunn <nathandunn@lbl.gov>
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update --fix-missing && \
    apt-get --no-install-recommends -y install \
    git build-essential maven openjdk-8-jdk libpq-dev postgresql-common \
    postgresql-client xmlstarlet netcat libpng-dev zlib1g-dev libexpat1-dev \
    ant curl ssl-cert python-pip python-numpy python-biopython python-setuptools \
    libyaml-dev libpython-dev jq && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get -qq update --fix-missing && \
    apt-get --no-install-recommends -y install nodejs && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cp /usr/lib/jvm/java-8-openjdk-amd64/lib/tools.jar /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/ext/tools.jar && \
    useradd -ms /bin/bash -d /apollo apollo

# 2.1.0
ENV WEBAPOLLO_VERSION 99c7e54c6e74fbc6705d57de216c9b14b2bfb03b
RUN curl -L https://github.com/GMOD/Apollo/archive/${WEBAPOLLO_VERSION}.tar.gz | tar xzf - --strip-components=1 -C /apollo

RUN cd /tmp && \
    git clone https://github.com/galaxy-genome-annotation/python-apollo && \
    cd python-apollo/ && \
    git checkout a5b506662d5124ff86bcff1b181b3f934070e6ca && \
    pip install . && \
    cd /apollo

COPY build.sh /bin/build.sh
ADD apollo-config.groovy /apollo/apollo-config.groovy

RUN chown -R apollo:apollo /apollo
USER apollo
RUN bash /bin/build.sh
USER root

ENV CONTEXT_PATH ROOT

RUN rm -rf ${CATALINA_HOME}/webapps/* && \
    cp /apollo/target/apollo*.war /apollo.war && \
    cp /apollo/target/apollo*.war ${CATALINA_HOME}/webapps/${CONTEXT_PATH}.war && \
    mkdir ${CATALINA_HOME}/webapps/${CONTEXT_PATH} && \
    cd ${CATALINA_HOME}/webapps/${CONTEXT_PATH} && \
    jar xvf ../${CONTEXT_PATH}.war && \
    cd /apollo

ADD canned_comments.txt canned_keys.txt canned_status.txt /bootstrap/

ADD launch.sh /launch.sh
ADD bootstrap.sh /bootstrap.sh
CMD "/launch.sh"
