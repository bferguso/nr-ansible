FROM registry.access.redhat.com/ubi7

# Prerequisites
RUN yum install -y gcc-c++ gzip make tar which tcl

# Sqlite
WORKDIR /tmp/sqlite
ARG SQLITE_VERSION
ENV SQLITE_VERSION=$SQLITE_VERSION
ENV SQLITE_URL https://github.com/sqlite/sqlite/archive/refs/tags/version-${SQLITE_VERSION}.tar.gz
RUN curl -L -s "${SQLITE_URL}" | tar xzv -C . --strip-components 1
RUN mkdir bld && \
    cd bld && \
    ../configure && \
    make && \
    make sqlite3.c

WORKDIR /dropbox
RUN mkdir ./sqlite && \
    cp /tmp/sqlite/bld/sqlite3 ./sqlite && \
    tar -czvf sqlite.tar.gz sqlite && \
    rm -rf ./sqlite
