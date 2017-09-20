#!/bin/bash

echo "Starting tomcat with $CATALINA_HOME"
$CATALINA_HOME/bin/startup.sh

if [[ ! -f "${CATALINA_HOME}/logs/catalina.out" ]]; then
	touch ${CATALINA_HOME}/logs/catalina.out
fi

touch /var/log/apollo_bootstrap.log

/bootstrap.sh > /var/log/apollo_bootstrap.log 2> /var/log/apollo_bootstrap.log &

tail -f ${CATALINA_HOME}/logs/catalina.out /var/log/apollo_bootstrap.log
