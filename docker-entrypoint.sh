#!/bin/bash
set -x

if [ "$(id -u)" = "0" ]; then
    # Add local user. Either use the ACTIVEMQ_USER_ID and ACTIVEMQ_GROUP_ID if 
    # passed in at runtime or fallback.
    USER_ID=${ACTIVEMQ_USER_ID:-`id -u activemq`}
    GROUP_ID=${ACTIVEMQ_GROUP_ID:-`id -g activemq`}
    echo "Starting with UID: $USER_ID GID: $GROUP_ID"
    usermod -u $USER_ID activemq
    groupmod -g $GROUP_ID activemq

    # Update permissions.
    chown -R activemq:activemq /data/activemq /var/log/activemq

    # Remove eventual lost+found directory from the data folder.
    if [ -d '/data/activemq/lost+found' ]; then
        rm -rf '/data/activemq/lost+found'
    fi
fi

# Update wrapper.conf.
if [ -n "${ACTIVEMQ_MIN_MEMORY}" ]; then
    # Replace wrapper.java.initmemory
    sed -i "s/^#?wrapper\\.java\\.initmemory=.*/wrapper.java.initmemory=${ACTIVEMQ_MIN_MEMORY}/g" "${WRAPPER_CONF}"
fi
if [ -n "${ACTIVEMQ_MAX_MEMORY}" ]; then
    # Replace wrapper.java.maxmemory
    sed -i "s/^#?wrapper\\.java\\.maxmemory=.*/wrapper.java.maxmemory=${ACTIVEMQ_MAX_MEMORY}/g" "${WRAPPER_CONF}"
fi

# Update jetty.xml
if [ -n "${ACTIVEMQ_ADMIN_PATH}" ]; then
    echo "Update admin path to ${ACTIVEMQ_ADMIN_PATH}"
    xmlstarlet ed --inplace --pf --ps --update '//bean[@class="org.eclipse.jetty.webapp.WebAppContext"][1]/property[@name="contextPath"]/@value' --value "${ACTIVEMQ_ADMIN_PATH}" "${JETTY_XML}"
fi
if [ -n "${ACTIVEMQ_API_PATH}" ]; then
    echo "Update api path to ${ACTIVEMQ_API_PATH}"
    xmlstarlet ed --inplace --pf --ps --update '//bean[@class="org.eclipse.jetty.webapp.WebAppContext"][2]/property[@name="contextPath"]/@value' --value "${ACTIVEMQ_API_PATH}" "${JETTY_XML}"
fi

exec "$@"
