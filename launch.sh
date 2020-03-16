#!/bin/bash

echo "Waiting for DB"
# Hacky, will only work with postgres.

DB_HOST=$(echo $WEBAPOLLO_DB_URI | sed 's|jdbc:postgresql://\([^/]\+\)/[^/]\+|\1|')
DB_NAME=$(echo $WEBAPOLLO_DB_URI | sed 's|jdbc:postgresql://[^/]\+/\([^/]\+\)|\1|')
DB_PORT="5432"

echo
echo "=> Trying to connect to a database using:"
echo "      Database Host:     $DB_HOST"
echo "      Database Port:     $DB_PORT"
echo "      Database Username: $WEBAPOLLO_DB_USERNAME"
echo "      Database Password: $WEBAPOLLO_DB_PASSWORD"
echo "      Database Name:     $DB_NAME"
echo

for ((i=0;i<20;i++))
do
    DB_CONNECTABLE=$(PGPASSWORD=$WEBAPOLLO_DB_PASSWORD psql -U "$WEBAPOLLO_DB_USERNAME" -h "$DB_HOST" -p "$DB_PORT" -l >/dev/null 2>&1; echo "$?")
	if [[ $DB_CONNECTABLE -eq 0 ]]; then
		break
	fi
    sleep 3
done

if ! [[ $DB_CONNECTABLE -eq 0 ]]; then
	echo "Cannot connect to database"
    exit "${DB_CONNECTABLE}"
fi

echo "DB ready, starting tomcat with $CATALINA_HOME"
$CATALINA_HOME/bin/startup.sh

if [[ ! -f "${CATALINA_HOME}/logs/catalina.out" ]]; then
	touch ${CATALINA_HOME}/logs/catalina.out
fi

touch /var/log/apollo_bootstrap.log

/bootstrap.sh > /var/log/apollo_bootstrap.log 2> /var/log/apollo_bootstrap.log &

tail -f ${CATALINA_HOME}/logs/catalina.out /var/log/apollo_bootstrap.log
