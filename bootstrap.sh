#!/bin/bash

echo "[BOOTSTRAP] Configuring Arrow in /root/.apollo-arrow.yml"

echo "__default: local" > '/root/.apollo-arrow.yml' &&
echo "local:" >> '/root/.apollo-arrow.yml' &&
echo "    url: \"http://apollo:8080\"" >> '/root/.apollo-arrow.yml' &&
echo "    username: \"$APOLLO_ADMIN_EMAIL\"" >> '/root/.apollo-arrow.yml' &&
echo "    password: \"$APOLLO_ADMIN_PASSWORD\"" >> '/root/.apollo-arrow.yml' &&

echo "[BOOTSTRAP] Waiting while Apollo starts up..."
# Wait for apollo to be online
for ((i=0;i<30;i++))
do
    APOLLO_UP=$(arrow users get_users 2> /dev/null | head -1 | grep '^\[$' -q; echo "$?")
	if [[ $APOLLO_UP -eq 0 ]]; then
		break
	fi
    sleep 10
done

echo "[BOOTSTRAP] Apollo is up, bootstrapping"

# Create a default group
DEFAULT_GROUP="annotators"
arrow groups create_group $DEFAULT_GROUP

for u in $(echo $APOLLO_REMOTE_ADMINS | tr "," "\n"); do
    if arrow users get_users | grep username | grep $u -q; then
        echo "[BOOTSTRAP] User $u already exists, skipping"
    else
        echo "[BOOTSTRAP] Creating admin REMOTE_USER $u"
        randomPass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

        arrow users create_user --role admin --metadata '{"INTERNAL_PASSWORD":"'$randomPass'"}' $u REMOTE_USER $u $randomPass
        arrow users add_to_group $DEFAULT_GROUP $u
    fi
done

# TODO add canned comments/status/keys
