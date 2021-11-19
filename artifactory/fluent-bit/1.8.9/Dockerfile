FROM registry.access.redhat.com/ubi7

ENV FLUENT_BIT_VERSION 1.8.9
RUN echo $'[td-agent-bit] \n\
name            = TD Agent Bit \n\
baseurl         = https://packages.fluentbit.io/centos/7/$basearch/ \n\
gpgcheck        = 1 \n\
gpgkey          = https://packages.fluentbit.io/fluentbit.key \n\
enabled         = 1 \n\
' > /etc/yum.repos.d/td-agent.bit.repo

RUN yum install -y td-agent-bit-${FLUENT_BIT_VERSION}

WORKDIR /dropbox
RUN mkdir ./fluent-bit && \
    cp /opt/td-agent-bit/bin/td-agent-bit ./fluent-bit/fluent-bit && \
    cp /usr/lib64/libpq.so.5.5 ./fluent-bit/libpq.so.5 && \
    tar -czvf fluent-bit.tar.gz ./fluent-bit && \
    rm -rf ./fluent-bit
