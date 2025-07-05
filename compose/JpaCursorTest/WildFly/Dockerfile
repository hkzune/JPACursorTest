FROM ubuntu:24.04

ARG JAVA_VERSION=21.0.4.7.1
ARG WF_MANAGEMENT_USER=admin
ARG WF_MANAGEMENT_PASSWORD=Admin
ARG HEAP_SIZE=4

ENV WF_MANAGEMENT_USER=$WF_MANAGEMENT_USER
ENV WF_MANAGEMENT_PASSWORD=$WF_MANAGEMENT_PASSWORD

RUN apt-get update && apt-get install -y \
    curl \
    fontconfig \
    gpg \
    gzip \
    locales-all \
    rsync \
    tar \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=ja_JP.UTF-8

# 初期設定用スクリプト実行のためにgetoptionsをインストール
RUN curl -LkvO https://github.com/ko1nksm/getoptions/releases/download/v3.3.2/getoptions \
    && chmod +x getoptions \
    && mv getoptions /usr/local/bin/getoptions

# Amazon Correttoのインストール
RUN wget -O corretto.tar.gz https://corretto.aws/downloads/resources/${JAVA_VERSION}/amazon-corretto-21.0.4.7.1-linux-x64.tar.gz \
    && mkdir -p /usr/lib/jvm \
    && tar -xzf corretto.tar.gz -C /usr/lib/jvm \
    && ln -s /usr/lib/jvm/amazon-corretto-${JAVA_VERSION}-linux-x64 /usr/lib/jvm/corretto-21 \
    && ln -s /usr/lib/jvm/corretto-21/bin/java /usr/bin/java \
    && rm corretto.tar.gz \
    && echo "export JAVA_HOME=/usr/lib/jvm/corretto-21" >> "/etc/profile.d/java.sh" \
    && echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile.d/java.sh

# WildFlyのインストール
RUN curl -LkvO https://github.com/wildfly/wildfly/releases/download/32.0.1.Final/wildfly-32.0.1.Final.tar.gz \ 
 	&& tar -xzf wildfly-32.0.1.Final.tar.gz --transform "s/wildfly-32.0.1.Final/wildfly/" \
    && rm wildfly-32.0.1.Final.tar.gz \
    && mkdir /opt/jboss \
    && mv wildfly /opt/jboss

ENV JBOSS_HOME=/opt/jboss/wildfly

# WildFlyの初期設定
COPY ./scripts /scripts
RUN ./scripts/setup.sh -H $HEAP_SIZE \
    # WildFlyの警告対策(https://github.com/jboss-dockerfiles/wildfly/issues/163)
    && rm -rf $JBOSS_HOME/standalone/configuration/standalone_xml_history


ENTRYPOINT [ "./scripts/entrypoint.sh" ]