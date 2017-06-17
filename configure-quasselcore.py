#!/usr/bin/env python2
# Script uses PyQt5 to write the docker parameters to a Quassel-with-LDAP
# compatible configuration file.

from __future__ import print_function

import sys
import os
import argparse
from PyQt5.QtCore import QSettings

if "QUASSEL_CONFIG_DIR" not in os.environ:
    raise Exception("QUASSEL_CONFIG_DIR not specified.")

settings = QSettings(os.path.join(os.environ["QUASSEL_CONFIG_DIR"],"quasselcore.conf"), QSettings.IniFormat)

def configure():
    # Set the config version to 1
    if settings.value("Config/Version") is None:
        settings.setValue("Config/Version", 1)

    # Set Auth Settings
    authSettings = {
        "Authenticator" : "LDAP",
        "AuthProperties" : {
            "BaseDN": os.environ["LDAP_BASE_DN"],
            "BindDN": os.environ["LDAP_BIND_DN"],
            "BindPassword": os.environ["LDAP_BIND_PASSWORD"],
            "Filter": os.environ["LDAP_FILTER"],
            "Hostname": os.environ["LDAP_HOSTNAME"],
            "Port": os.environ["LDAP_PORT"],
            "UidAttribute": os.environ["LDAP_UID_ATTR"]
        }
    }
    settings.setValue("Core/AuthSettings", authSettings)

    # Set Storage Settings
    storageSettings = {
        "Backend" : "PostgreSQL",
        "ConnectionProperties" : {
            "Database": os.environ["POSTGRES_DATABASE"],
            "Hostname": os.environ["POSTGRES_HOSTNAME"],
            "Port": os.environ["POSTGRES_PORT"],
            "Username": os.environ["POSTGRES_USER"],
            "Password": os.environ["POSTGRES_PASSWORD"]
        }
    }
    settings.setValue("Core/StorageSettings", storageSettings)

    settings.sync()

    sys.exit(0)
    
def dump():
    for key in settings.allKeys():
        print(settings.value(key))
    sys.exit(0)
        
if __name__ == "__main__":
    parser = argparse.ArgumentParser("configure the quasselcore file on launch")
    parser.add_argument("op", choices=("configure","dump"))
    args = parser.parse_args()
    
    locals()[args.op]()


