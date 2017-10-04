# Apollo
# VERSION 2.0.7
FROM tomcat:8-jre8
MAINTAINER Anthony Bretaudeau <anthony.bretaudeau@inra.fr>, Eric Rasche <esr@tamu.edu>, Nathan Dunn <nathandunn@lbl.gov>
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update --fix-missing && \
    apt-get --no-install-recommends -y install \
    git build-essential maven openjdk-8-jdk libpq-dev postgresql-common \
    postgresql-client xmlstarlet netcat libpng-dev zlib1g-dev libexpat1-dev \
    ant curl ssl-cert python-pip python-numpy python-biopython python-setuptools \
    libyaml-dev libpython-dev && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get -qq update --fix-missing && \
    apt-get --no-install-recommends -y install nodejs && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cp /usr/lib/jvm/java-8-openjdk-amd64/lib/tools.jar /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/ext/tools.jar && \
    useradd -ms /bin/bash -d /apollo apollo

# 2.0.7
ENV WEBAPOLLO_VERSION dedf92f7da805620d2dbfb88a8129d025fec7059
RUN curl -L https://github.com/GMOD/Apollo/archive/${WEBAPOLLO_VERSION}.tar.gz | tar xzf - --strip-components=1 -C /apollo

RUN cd /tmp && \
    git clone https://github.com/galaxy-genome-annotation/python-apollo && \
    cd python-apollo/ && \
    git checkout 32cd4871bc740a79b493b60651262a71b6174668 && \
    pip install . && \
    cd /apollo

ADD PR1754.diff PR1751.diff PR1774.diff PR1775.diff /apollo/

RUN cd /apollo && \
    patch -p1 < PR1751.diff && \
    patch -p1 < PR1754.diff && \
    patch -p1 < PR1774.diff && \
    patch -p1 < PR1775.diff

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
