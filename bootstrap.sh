#!/bin/bash

. /opt/arrow_venv/bin/activate

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

if ! [[ $APOLLO_UP -eq 0 ]]; then
        echo "Cannot connect to apollo for bootstrapping"
    exit "${APOLLO_UP}"
fi

echo "[BOOTSTRAP] Apollo is up, bootstrapping"

# Create a default group
DEFAULT_GROUP="annotators"
if arrow groups get_groups | grep name | grep $DEFAULT_GROUP -q; then
    echo "[BOOTSTRAP] Group $u already exists, skipping"
else
    echo "[BOOTSTRAP] Creating group $DEFAULT_GROUP"
    arrow groups create_group $DEFAULT_GROUP
fi

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

if [ -f /bootstrap/canned_comments.txt ]; then
    while read c; do
        if ! arrow cannedcomments show_comment "$c" > /dev/null 2>&1; then
            arrow cannedcomments add_comment "$c"
        else
            echo "[BOOTSTRAP] Canned comment $c already exists, skipping"
        fi
    done < /bootstrap/canned_comments.txt
fi

if [ -f /bootstrap/canned_keys.txt ]; then
    while read c; do
        if ! arrow cannedkeys show_key "$c" > /dev/null 2>&1; then
            arrow cannedkeys add_key "$c"
        else
            echo "[BOOTSTRAP] Canned key $c already exists, skipping"
        fi
    done < /bootstrap/canned_keys.txt
fi

if [ -f /bootstrap/canned_values.txt ]; then
    while read c; do
        if ! arrow cannedvalues show_value "$c" > /dev/null 2>&1; then
            arrow cannedvalues add_value "$c"
        else
            echo "[BOOTSTRAP] Canned value $c already exists, skipping"
        fi
    done < /bootstrap/canned_values.txt
fi

if [ -f /bootstrap/canned_status.txt ]; then
    while read c; do
        if ! arrow status show_status "$c" > /dev/null 2>&1; then
            arrow status add_status "$c"
        else
            echo "[BOOTSTRAP] Canned status $c already exists, skipping"
        fi
    done < /bootstrap/canned_status.txt
fi
