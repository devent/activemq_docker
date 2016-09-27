FROM java:8

# Configuration variables.
ENV ACTIVEMQ_VERSION 5.14.0
ENV ACTIVEMQ_HOME /opt/activemq
ENV ACTIVEMQ_ARCHIVE apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz
ENV ACTIVEMQ_URL http://apache.mirrors.ovh.net/ftp.apache.org/dist/activemq/${ACTIVEMQ_VERSION}/apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz
ENV LOG_DIR /var/log/activemq
ENV DATA_DIR /data/activemq
ENV START_SCRIPT $ACTIVEMQ_HOME/bin/linux-x86-64/activemq
ENV WRAPPER_CONF $ACTIVEMQ_HOME/bin/linux-x86-64/wrapper.conf
ENV JETTY_XML $ACTIVEMQ_HOME/conf/jetty.xml

# Create activeMQ user and group.
RUN set -x \
    && groupadd activemq \
    && useradd --system --home ${ACTIVEMQ_HOME} -g activemq activemq

# Install xmlstarlet to configure the activeMQ XML files.
RUN set -x \
    && apt-get update --quiet \
    && apt-get install --quiet --yes --no-install-recommends libtcnative-1 xmlstarlet \
    && apt-get clean

# Only for development.
# COPY $ACTIVEMQ_ARCHIVE /tmp/$ZIMBRA_ARCHIVE

# Install activeMQ.
RUN set -x \
    && cd "/tmp" \
    # Download if no local file is available.
    && if [ -z "`find $ACTIVEMQ_ARCHIVE -size +0`" ]; then curl -LO "${ACTIVEMQ_URL}"; fi \
    && tar -xzf apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz \
    && mv apache-activemq-${ACTIVEMQ_VERSION} ${ACTIVEMQ_HOME} \
    # Set user and mod.
    && chmod -R 700 "${ACTIVEMQ_HOME}" \
    && chown -R activemq:activemq "${ACTIVEMQ_HOME}" \
    && mkdir -p "${DATA_DIR}" \
    && chown -R activemq:activemq "${DATA_DIR}" \
    && mkdir -p "${LOG_DIR}" \
    && chown -R activemq:activemq "${LOG_DIR}"

# Configure activeMQ script.
RUN set -x \
    && sed -ri "s/^#?RUN_AS_USER=.*/RUN_AS_USER=activemq/" "${START_SCRIPT}"

# Configure directories in wrapper.conf.
RUN set -x \
    && sed -ri "s|^set\\.default\\.ACTIVEMQ_DATA=.*|set.default.ACTIVEMQ_DATA=${DATA_DIR}|" "${WRAPPER_CONF}" \
    && sed -ri "s|^wrapper\\.logfile=.*|wrapper.logfile=${LOG_DIR}/wrapper.log|" "${WRAPPER_CONF}"

# Use the default unprivileged account.
USER activemq:activemq

# Expose activeMQ ports.
EXPOSE 8161
EXPOSE 61616
EXPOSE 5672
EXPOSE 61613
EXPOSE 1883
EXPOSE 61614

# Expose activeMQ directories.
VOLUME ["/data/activemq"]
VOLUME ["/var/log/activemq"]
VOLUME ["/opt/activemq/conf"]

# Set the default working directory as the installation directory.
WORKDIR /opt/activemq

# Set the docker entry point script.
COPY "docker-entrypoint.sh" "/"
ENTRYPOINT ["/docker-entrypoint.sh"]

# Run activeMQ as a foreground process by default.
CMD ["/opt/activemq/bin/linux-x86-64/activemq", "console"]
