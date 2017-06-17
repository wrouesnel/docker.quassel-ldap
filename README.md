# LDAP authed, Postgres-backed Quassel Core Server

Dockerfile to build and deploy a totally stateless quassel LDAP container that
is fully configured by environment variables on startup.

The server listens on port `4242/tcp`.

## Environment

* `DATA_DIR` Default `/data`.
* `POSTGRES_HOSTNAME` Hostname of the Postgres server for persistence.
* `POSTGRES_PORT` Port of the Postgres server for persistence.
* `POSTGRES_USER` Username for connecting to the Postgres database.
* `POSTGRES_PASSWORD` Password for connecting to Postgres database.
* `POSTGRES_DATABASE` Name of the postgres database to connect to.
* `LDAP_HOSTNAME` URI of the LDAP server - e.g. `ldap://localhost` or `ldaps://localhost`
* `LDAP_PORT` Port of the LDAP server.
* `LDAP_BIND_DN` Bind DN of the LDAP server.
* `LDAP_BIND_PASSWORD` Bind password for the bind DN of the LDAP server.
* `LDAP_BASE_DN` Search base DN of the LDAP server.
* `LDAP_FILTER` Search filter for user accounts on the LDAP server e.g. `(objectClass=posixAccount)`
* `LDAP_UID_ATTR` UID attribute to use for finding user accounts. e.g. `uid`
* `SSL_CERT` Required. Either a literal certificate or the path to a certificate.
* `SSL_KEY` Required. Either a literal key or the path to a key in the container.

### Debug Environment
* `DEV_ALLOW_EPHEMERAL_DATA` Default `no`. Disables the check for a mounted `DATA_DIR` directory.
* `DEV_QUASSEL_DEBUG` Default `no`. Sets the `--debug` flag when Quassel is launched.

