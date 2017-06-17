# Build it
FROM ubuntu:zesty AS build
MAINTAINER Will Rouesnel <w.rouesnel@gmail.com>

RUN apt-get update && apt-get install -y \
    build-essential make cmake git qt5-default pkg-config libqca-qt5-2 \
    libqca-qt5-2-plugins libqt5script5 qtscript5-dev qttools5-dev-tools \
    libldap2-dev libqt5sql5-psql

RUN mkdir src && \
    git clone https://github.com/jhuacm/quassel.git src && \
    cd src && git checkout d9266496ec207e263b431dcfb6b3d6aab60adca1 && \
    mkdir build && \
    cd build && \
    cmake -DWANT_QTCLIENT=OFF -DWANT_MONO=OFF -DWANT_CORE=ON -DWITH_BREEZE=OFF \
        .. && \
    make && \
    make install

# Deploy it.
FROM ubuntu:zesty

# Install python and python-qtpy so we can write configuration files.
RUN apt-get update && apt-get install -y --no-install-recommends \
    python-qtpy python openssl libqt5sql5-sqlite libqt5sql5-psql libldap-2.4-2 \
    libqt5script5 libqca-qt5-2 libqca-qt5-2-plugins

# Above we install quassel-core pretty bluntly to /usr/local. Since we rebuild
# the runtime environment here, we can just do a 1:1 copy.
COPY --from=build /usr/local/ /usr/local/

ENV \
    DEV_ALLOW_EPHEMERAL_DATA=no \
    DEV_QUASSEL_DEBUG=no \
    DATA_DIR=/data \
    POSTGRES_HOSTNAME= \
    POSTGRES_PORT= \
    POSTGRES_USER= \
    POSTGRES_PASSWORD= \
    POSTGRES_DATABASE= \
    LDAP_HOSTNAME= \
    LDAP_PORT= \
    LDAP_BIND_DN= \
    LDAP_BIND_PASSWORD= \
    LDAP_BASE_DN= \
    LDAP_FILTER= \
    LDAP_UID_ATTR=

EXPOSE 4242/tcp

COPY configure-quasselcore.py /configure-quasselcore.py
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
