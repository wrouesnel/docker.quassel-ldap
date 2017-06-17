#!/bin/bash

# Ensure a private umask since we do a lot of SSL handling.
umask 077

# Ensure postgres is in the path.
export PATH=/usr/lib/postgresql/9.6/bin:$PATH

function log() {
    echo "$@"
}

function echoerr() {
    echo "$@" 1>&2
}

function genpassword() {
    echo $(pwgen 48 1)
}

function stdbool() {
    if [ -z "$1" ] ; then
        echo "n"
    else
        echo ${1:0:1} | tr [A-Z] [a-z]
    fi
}

# Reads the given environment variable name, detects if its a file and templates
# it out to the given output file path. Optionally allows the process to be skipped
# if the value is blank.
# Usage: handle_file_input_envvar <options> ENVVAR OUTFILE
# Valid options: --can-disable --allow-blank --append
function handle_file_input_envvar() {
    local can_disable allow_blank do_append

    while true; do
        case $1 in
        --can-disable) can_disable=y ; shift ;;
        --allow-blank) allow_blank=y ; shift ;;
        --append) do_append=y ; shift ;;
        *)
            if [ "${1:0:2}" != "--" ] ; then
                break
            else  
                log "handle_file_input_envvar: Unknown option received: $1"
                exit 1
            fi
            ;;
        esac
    done

    local envvar="$1"
    local outfile="$2"
    
    # Sanity checks
    if [ "$#" -ne 2 ] ; then
        log "handle_file_input_envvar: Got $# arguments, expected 2."
        exit 1
    fi
    
    eval local envval="\$$envvar"

    if [ "${can_disable}" = "y" ] && [ "${envval}" = "disabled" ] ; then
        log "$envvar disabled by user requested."
        return
    elif [ "${envval}" = "disabled" ] ; then
        log "$envvar is set to \"disabled\" but this value is mandatory."
        exit 1
    fi
    
    if [ -z "${envval}" ] && [ "y" != "${allow_blank}" ]; then
        log "$envvar is blank instead of being explicitly disabled and must contain a value."
        exit 1
    fi
    
    if [ "${envval:0:1}" = "/" ] ; then
        log "$envvar is path."
        if [ ! -e "$envval" ] ; then
            log "$envval does not exist."
            exit 1
        fi
        
        if [ "$do_append" = "y" ] ; then
            cat "$envval" >> "$outfile"
        else
            cat "$envval" > "$outfile"
        fi
    else
        log "$envvar is literal."

        if [ "$do_append" = "y" ] ; then
            echo -n "$envval" >> "$outfile"
        else
            echo -n "$envval" > "$outfile"
        fi
    fi
}

export DATA_DIR

log "Checking persistent data directory is valid"
if ! mountpoint "$DATA_DIR" && [ $(stdbool $DEV_ALLOW_EPHEMERAL_DATA) != "y" ] ; then
    log "$DATA_DIR is not a mountpoint. Data will not persist, and this is not allowed."
    exit 1
elif ! mountpoint "$DATA_DIR" ; then
    echoerr "WARNING: allowing an ephemeral data directory."
    mkdir -m 755 -p "$DATA_DIR"
fi

export QUASSEL_CONFIG_DIR="${DATA_DIR}/config"

log "Ensuring quassel config-dir exists: ${QUASSEL_CONFIG_DIR}"
mkdir -m 750 -p "${QUASSEL_CONFIG_DIR}"

# Invoke the python script to configure quasselcore
if ! /configure-quasselcore.py configure ; then
    echoerr "configure-quasselcore.py failed. Cannot proceed."
    exit 1
fi

QUASSEL_EXTRA_OPTS=

if [ $(stdbool $DEV_QUASSEL_DEBUG) == "y" ] ; then
    QUASSEL_EXTRA_OPTS="--debug $QUASSEL_EXTRA_OPTS"
fi

log "Setup successful. Starting Quassel Core."
exec quasselcore $QUASSEL_EXTRA_OPTS \
    --configdir "$QUASSEL_CONFIG_DIR"
