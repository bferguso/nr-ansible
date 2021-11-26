FROM registry.access.redhat.com/ubi7

RUN rpm -i https://packages.fluentbit.io/centos/7/x86_64/td-agent-bit-1.8.7-1.x86_64.rpm

WORKDIR /dropbox
RUN mkdir ./fluent-bit && \
    cp /opt/td-agent-bit/bin/td-agent-bit ./fluent-bit/fluent-bit && \
    cp /usr/lib64/libpq.so.5 ./fluent-bit && \
    tar -czvf fluent-bit.tar.gz fluent-bit && \
    rm -rf ./fluent-bit
