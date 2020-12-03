ARG NODE_VERSION=12
ARG PYTHON_VERSION=3.8

#
# --- Build assets with NodeJS
#

FROM node:${NODE_VERSION} AS build

# Superset version to build
ARG SUPERSET_VERSION=0.38.0
ENV SUPERSET_HOME=/var/lib/superset/

# Download source
WORKDIR ${SUPERSET_HOME}
RUN wget -qO /tmp/superset.tar.gz https://github.com/apache/incubator-superset/archive/${SUPERSET_VERSION}.tar.gz
RUN tar xzf /tmp/superset.tar.gz -C ${SUPERSET_HOME} --strip-components=1

# Build assets
WORKDIR ${SUPERSET_HOME}/superset-frontend
COPY ./custom/casebook-logo-252x58.png images/casebook-logo-252x58.png
COPY ./custom/casebook-icon-16x16.png images/favicon.png
RUN \
  sed -i 's/superset-logo-horiz.png/casebook-logo-252x58.png/g' ../superset/config.py && \
  sed -i 's/\"Superset\"/\"Casebook\"/g' ../superset/config.py && \
  mkdir -p stylesheets/less/cbp
COPY custom/stylesheets/index.less stylesheets/less/index.less
COPY custom/stylesheets/cbp/* stylesheets/less/cbp/

RUN \
  npm install && \
  npm run build

#
# --- Build dist package with Python 3
#

FROM python:${PYTHON_VERSION} AS dist

# Copy prebuilt workspace into stage
ENV SUPERSET_HOME=/var/lib/superset/
WORKDIR ${SUPERSET_HOME}
COPY --from=build ${SUPERSET_HOME} .
COPY requirements.txt .

# Create package to install
RUN python setup.py sdist
RUN tar czfv /tmp/superset.tar.gz requirements.txt dist

#
# --- Install dist package and finalize app
#

FROM python:${PYTHON_VERSION} AS final

# Configure environment
# superset recommended defaults: https://superset.apache.org/docs/installation/configuring-superset#running-on-a-wsgi-http-server
# gunicorn recommended defaults: https://docs.gunicorn.org/en/0.17.2/configure.html#security
ENV GUNICORN_BIND=0.0.0.0:8088 \
    GUNICORN_LIMIT_REQUEST_FIELD_SIZE=8190 \
    GUNICORN_LIMIT_REQUEST_LINE=4094 \
    GUNICORN_THREADS=4 \
    GUNICORN_TIMEOUT=120 \
    GUNICORN_WORKERS=10 \
    GUNICORN_WORKER_CLASS=gevent \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONPATH=/etc/superset:/home/superset:$PYTHONPATH \
    SUPERSET_REPO=apache/incubator-superset \
    SUPERSET_VERSION=${SUPERSET_VERSION} \
    SUPERSET_HOME=/var/lib/superset
ENV GUNICORN_CMD_ARGS="--bind ${GUNICORN_BIND} --limit-request-field_size ${GUNICORN_LIMIT_REQUEST_FIELD_SIZE} --limit-request-line ${GUNICORN_LIMIT_REQUEST_LINE} --threads ${GUNICORN_THREADS} --timeout ${GUNICORN_TIMEOUT} --workers ${GUNICORN_WORKERS} --worker-class ${GUNICORN_WORKER_CLASS}"

# Create superset user & install dependencies
WORKDIR /tmp/superset
COPY --from=dist /tmp/superset.tar.gz .
RUN groupadd supergroup && \
    useradd -U -m -G supergroup superset && \
    mkdir -p /etc/superset && \
    mkdir -p ${SUPERSET_HOME} && \
    chown -R superset:superset /etc/superset && \
    chown -R superset:superset ${SUPERSET_HOME} && \
    apt-get update && \
    apt-get install -y \
        apt-utils \
        build-essential \
        curl \
        default-libmysqlclient-dev \
        freetds-bin \
        freetds-dev \
        libaio1 \
        libffi-dev \
        libldap2-dev \
        libpq-dev \
        libsasl2-2 \
        libsasl2-dev \
        libsasl2-modules-gssapi-mit \
        libssl-dev && \
    tar xzf superset.tar.gz && \
    pip install pip --upgrade && \
    pip install numpy==1.18.5 && \
    pip install pandas==1.0.4 && \
    pip install convertdate==2.2.1 && \
    pip install LunarCalendar==0.0.9 && \
    pip install holidays==0.10.2 && \
    pip install matplotlib==3.2.1 && \
    pip install plotly==4.8.1 && \
    pip install pystan==2.19.1.1 && \
    pip install tqdm && \
    pip install Cython==0.29.21 && \
    pip install dist/*.tar.gz -r requirements.txt && \
    rm -rf ./*

# Configure Filesystem
COPY bin /usr/local/bin
WORKDIR /home/superset
VOLUME /etc/superset \
       /home/superset \
       /var/lib/superset

# Finalize application
EXPOSE 8088
HEALTHCHECK CMD ["curl", "-f", "http://localhost:8088/health"]
CMD ["gunicorn", "superset.app:create_app()"]
USER superset
