#!/bin/bash
 
set -e
set -u

if [ ${ENABLE_SEALER_KEY_ROTATION:=True} -eq 'True' ]
then

 # Default IDP_HOME if not already set
 if [ ! -d "${IDP_HOME:=/opt/shibboleth-idp}" ]
 then
    echo "ERROR: Directory does not exist: ${IDP_HOME}" >&2
    exit 1
 fi

 # Default JAVA_HOME if not already set
 if [ -d "${JAVA_HOME:=/usr}" ]
 then
    export JAVA_HOME=${JAVA_HOME:=/usr}
 else
    echo "ERROR: JAVA_HOME Directory does not exist: ${JAVA_HOME:=/usr}" >&2
    exit 1
 fi

 function get_config {
    # Key to lookup (escape . for regex lookup)
    local KEY=${1:?"No key provided to look up value"}
    # Passed default value
    local DEFAULT="${2:-}"
    # Lookup key, strip spaces, replace idp.home with IDP_HOME value
    local RESULT=$(sed -rn '/^'"${KEY//./\\.}"'\s*=/ { s|^[^=]*=(.*)\s*$|\1|; s|%\{idp\.home\}|'"${IDP_HOME}"'|g; p}' ${IDP_HOME}/conf/idp.properties)
    # Set if no result with default - exit if no default
    echo ${RESULT:-${DEFAULT:?"No value in config and no default defined for: '${KEY}'"}}
 }
 
 # Get config values
 ## Official config items ##
 storefile=$(get_config idp.sealer.storeResource)
 versionfile=$(get_config idp.sealer.versionResource)
 storepass=$(get_config idp.sealer.storePassword)
 alias=$(get_config idp.sealer.aliasBase secret)
 ## Extended config items ##
 count=$(get_config idp.sealer._count 30)
 # default cannot be empty - so "self" is the default (self is skipped for syncing)
 sync_hosts=$(get_config idp.sealer._sync_hosts ${HOSTNAME})
 
 # Run the keygen utility
 ${0%/*}/runclass.sh net.shibboleth.utilities.java.support.security.BasicKeystoreKeyStrategyTool \
    --storefile "${storefile}" \
    --storepass "${storepass}" \
    --versionfile "${versionfile}" \
    --alias "${alias}" \
    --count "${count}"
 
 # Display current version
 echo "INFO: $(tac "${versionfile}" | tr "\n" " ")" >&2
 
 for EACH in ${sync_hosts}
 do
    if [ "${HOSTNAME}" == "${EACH}" ]
    then
        echo "INFO: Host '${EACH}' is myself - skipping" >&2
    elif ! ping -q -c 1 -W 3 ${EACH} >/dev/null 2>&1
    then
        echo "ERROR: Host '${EACH}' not reachable - skipping" >&2
    else
        # run scp in the background
        scp "${storefile}" "${versionfile}" "${EACH}:${IDP_HOME}/credentials/" &
    fi
 done

fi
