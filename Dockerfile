# syntax=docker/dockerfile:1.3
FROM node:14 AS frontend-builder
# [frontend-builder 1/5] FROM docker.io/library/node:14

ENV NPM_CACHE_LOCATION=$HOME/.npm \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

WORKDIR /label-studio/label_studio/frontend
# [frontend-builder 2/5] WORKDIR /label-studio/label_studio/frontend

COPY --chown=1001:0 label_studio/frontend .
# [frontend-builder 3/5] COPY --chown=1001:0 label_studio/frontend .

COPY --chown=1001:0 label_studio/__init__.py /label-studio/label_studio/__init__.py
# [frontend-builder 4/5] COPY --chown=1001:0 label_studio/__init__.py /label-studio/label_studio/__init__.py

RUN --mount=type=cache,target=$NPM_CACHE_LOCATION,uid=1001,gid=0 \
    npm ci \
 && npm run build:production
# [frontend-builder 5/5] RUN --mount=type=cache,target=/.npm,uid=1001,gid=0 npm ci && npm run build:production

FROM ubuntu:22.04
# [stage-1  1/16] FROM docker.io/library/ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LS_DIR=/label-studio \
    PIP_CACHE_DIR=$HOME/.cache \
    DJANGO_SETTINGS_MODULE=core.settings.label_studio \
    LABEL_STUDIO_BASE_DATA_DIR=/label-studio/data \
    OPT_DIR=/opt/heartex/instance-data/etc \
    SETUPTOOLS_USE_DISTUTILS=stdlib

WORKDIR $LS_DIR
# [stage-1  2/16] WORKDIR /label-studio

# install packages
RUN set -eux \
 && apt-get update \
 && apt-get install --no-install-recommends --no-install-suggests -y \
    build-essential postgresql-client libmysqlclient-dev mysql-client python3-pip python3-dev \
    git libxml2-dev libxslt-dev zlib1g-dev gnupg curl lsb-release libpq-dev dnsutils vim && \
    apt-get purge --assume-yes --auto-remove --option APT::AutoRemove::RecommendsImportant=false \
     --option APT::AutoRemove::SuggestsImportant=false && rm -rf /var/lib/apt/lists/* /tmp/*
# [stage-1  3/16] RUN
# set -eux &&
# apt-get update &&
# apt-get install --no-install-recommends --no-install-suggests -y build-essential postgresql-client libmysqlclient-dev mysql-client python3-pip python3-dev git libxml2-dev libxslt-dev zlib1g-dev gnupg curl lsb-release libpq-dev dnsutils vim &&
# apt-get purge --assume-yes --auto-remove --option APT::AutoRemove::RecommendsImportant=false --option APT::AutoRemove::SuggestsImportant=false && rm -rf /var/lib/apt/lists/* /tmp/*

RUN --mount=type=cache,target=$PIP_CACHE_DIR,uid=1001,gid=0 \
    pip3 install --upgrade pip setuptools && pip3 install uwsgi uwsgitop -i https://pypi.tuna.tsinghua.edu.cn/simple
# [stage-1  4/16] RUN --mount=type=cache,target=/.cache,uid=1001,gid=0 pip3 install --upgrade pip setuptools && pip3 install uwsgi uwsgitop

# incapsulate nginx install & configure to a single layer
RUN set -eux; \
    curl -sSL https://nginx.org/keys/nginx_signing.key | apt-key add - && \
    echo "deb https://nginx.org/packages/mainline/ubuntu/ $(lsb_release -cs) nginx" >> /etc/apt/sources.list && \
    apt-get update && apt-get install -y nginx && \
    apt-get purge --assume-yes --auto-remove --option APT::AutoRemove::RecommendsImportant=false \
     --option APT::AutoRemove::SuggestsImportant=false && rm -rf /var/lib/apt/lists/* /tmp/* && \
    nginx -v
# [stage-1  5/16] RUN
# set -eux; curl -sSL https://nginx.org/keys/nginx_signing.key | apt-key add - &&
# echo "deb https://nginx.org/packages/mainline/ubuntu/ $(lsb_release -cs) nginx" >> /etc/apt/sources.list &&
# apt-get update &&
# apt-get install -y nginx &&
# apt-get purge --assume-yes --auto-remove --option APT::AutoRemove::RecommendsImportant=false --option APT::AutoRemove::SuggestsImportant=false && rm -rf /var/lib/apt/lists/* /tmp/* &&
# nginx -v

COPY --chown=1001:0 deploy/default.conf /etc/nginx/nginx.conf
# [stage-1  6/16] COPY --chown=1001:0 deploy/default.conf /etc/nginx/nginx.conf

RUN set -eux; \
    mkdir -p $OPT_DIR /var/log/nginx /var/cache/nginx /etc/nginx && \
    chown -R 1001:0 $OPT_DIR /var/log/nginx /var/cache/nginx /etc/nginx
# [stage-1  7/16] RUN
# set -eux; mkdir -p /opt/heartex/instance-data/etc /var/log/nginx /var/cache/nginx /etc/nginx &&
# chown -R 1001:0 /opt/heartex/instance-data/etc /var/log/nginx /var/cache/nginx /etc/nginx

# Copy and install middleware dependencies
COPY --chown=1001:0 deploy/requirements-mw.txt .
# [stage-1  8/16] COPY --chown=1001:0 deploy/requirements-mw.txt .

RUN --mount=type=cache,target=$PIP_CACHE_DIR,uid=1001,gid=0 \
    pip3 install -r requirements-mw.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
# [stage-1  9/16] RUN --mount=type=cache,target=/.cache,uid=1001,gid=0 pip3 install -r requirements-mw.txt

# Copy and install requirements.txt first for caching
COPY --chown=1001:0 deploy/requirements.txt .
# [stage-1 10/16] COPY --chown=1001:0 deploy/requirements.txt .

RUN --mount=type=cache,target=$PIP_CACHE_DIR,uid=1001,gid=0 \
    pip3 install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
# [stage-1 11/16] RUN --mount=type=cache,target=/.cache,uid=1001,gid=0 pip3 install -r requirements.txt

COPY --chown=1001:0 . .
# [stage-1 12/16] COPY --chown=1001:0 . .

RUN --mount=type=cache,target=$PIP_CACHE_DIR,uid=1001,gid=0 \
    pip3 install -e . && \
    chown -R 1001:0 $LS_DIR && \
    chmod -R g=u $LS_DIR
# [stage-1 13/16] RUN --mount=type=cache,target=/.cache,uid=1001,gid=0 pip3 install -e . && chown -R 1001:0 /label-studio && chmod -R g=u /label-studio

RUN rm -rf ./label_studio/frontend
# [stage-1 14/16] RUN rm -rf ./label_studio/frontend

COPY --chown=1001:0 --from=frontend-builder /label-studio/label_studio/frontend/dist ./label_studio/frontend/dist
# [stage-1 15/16] COPY --chown=1001:0 --from=frontend-builder /label-studio/label_studio/frontend/dist ./label_studio/frontend/dist

RUN python3 label_studio/manage.py collectstatic --no-input && \
    chown -R 1001:0 $LS_DIR && \
    chmod -R g=u $LS_DIR
# [stage-1 16/16] RUN
# python3 label_studio/manage.py collectstatic --no-input &&
# chown -R 1001:0 /label-studio &&
# chmod -R g=u /label-studio

ENV HOME=/label-studio

EXPOSE 8080

USER 1001

ENTRYPOINT ["./deploy/docker-entrypoint.sh"]
CMD ["label-studio"]
