#!/bin/sh -e
# Copyright (c) 2021 Deepak Singh

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

scripts_dir='/opt/nifi/scripts'

[ -f "${scripts_dir}/common.sh" ] && . "${scripts_dir}/common.sh"

# Override JVM memory settings
if [ ! -z "${NIFI_JVM_HEAP_INIT}" ]; then
    prop_replace 'java.arg.2'       "-Xms${NIFI_JVM_HEAP_INIT}" ${nifi_bootstrap_file}
fi

if [ ! -z "${NIFI_JVM_HEAP_MAX}" ]; then
    prop_replace 'java.arg.3'       "-Xmx${NIFI_JVM_HEAP_MAX}" ${nifi_bootstrap_file}
fi

if [ ! -z "${NIFI_JVM_DEBUGGER}" ]; then
    uncomment "java.arg.debug" ${nifi_bootstrap_file}
fi
##################################
# Core Properties
##################################
prop_replace 'nifi.web.https.port'              "${NIFI_WEB_HTTPS_PORT:-8443}"
prop_replace 'nifi.web.https.host'              "${NIFI_WEB_HTTPS_HOST:-$HOSTNAME}"
prop_replace 'nifi.web.proxy.host'              "${NIFI_WEB_PROXY_HOST}"
prop_replace 'nifi.remote.input.host'           "${NIFI_REMOTE_INPUT_HOST:-$HOSTNAME}"
prop_replace 'nifi.remote.input.socket.port'    "${NIFI_REMOTE_INPUT_SOCKET_PORT:-10000}"
prop_replace 'nifi.remote.input.secure'         'true'
prop_replace 'nifi.remote.input.http.enabled'   'true'

if [ -n "${NIFI_WEB_HTTP_PORT}" ]; then
    prop_replace 'nifi.web.https.port'                        ''
    prop_replace 'nifi.web.https.host'                        ''
    prop_replace 'nifi.web.http.port'                         "${NIFI_WEB_HTTP_PORT}"
    prop_replace 'nifi.web.http.host'                         "${NIFI_WEB_HTTP_HOST:-$HOSTNAME}"
    prop_replace 'nifi.remote.input.secure'                   'false'
    prop_replace 'nifi.cluster.protocol.is.secure'            'false'
    prop_replace 'nifi.security.keystore'                     ''
    prop_replace 'nifi.security.keystoreType'                 ''
    prop_replace 'nifi.security.truststore'                   ''
    prop_replace 'nifi.security.truststoreType'               ''
    prop_replace 'nifi.security.user.login.identity.provider' ''

    if [ -n "${NIFI_WEB_PROXY_HOST}" ]; then
        echo 'NIFI_WEB_PROXY_HOST was set but NiFi is not configured to run in a secure mode. Unsetting nifi.web.proxy.host.'
        prop_replace 'nifi.web.proxy.host' ''
    fi
else
    if [ -z "${NIFI_WEB_PROXY_HOST}" ]; then
        echo 'NIFI_WEB_PROXY_HOST was not set but NiFi is configured to run in a secure mode. The NiFi UI may be inaccessible if using port mapping or connecting through a proxy.'
    fi
fi
##################################
# Zookeeper and cluster properties
##################################
prop_replace 'nifi.cluster.protocol.is.secure'              'true'
prop_replace 'nifi.cluster.load.balance.host'               "${NIFI_CLUSTER_LB_HOST:-}"
prop_replace 'nifi.cluster.load.balance.port'               "${NIFI_CLUSTER_LB_PORT:-6342}"
prop_replace 'nifi.cluster.is.node'                         "${NIFI_CLUSTER_IS_NODE:-false}"
prop_replace 'nifi.cluster.node.address'                    "${NIFI_CLUSTER_ADDRESS:-$HOSTNAME}"
prop_replace 'nifi.cluster.node.protocol.port'              "${NIFI_CLUSTER_NODE_PROTOCOL_PORT:-}"
prop_replace 'nifi.zookeeper.connect.string'                "${NIFI_ZK_CONNECT_STRING:-}"
prop_replace 'nifi.zookeeper.root.node'                     "${NIFI_ZK_ROOT_NODE:-/nifi}"
prop_replace 'nifi.cluster.flow.election.max.wait.time'     "${NIFI_ELECTION_MAX_WAIT:-5 mins}"
prop_replace 'nifi.cluster.flow.election.max.candidates'    "${NIFI_ELECTION_MAX_CANDIDATES:-}"
prop_replace 'nifi.state.management.provider.local'         "${NIFI_STATE_MANAGEMENT_PROVIDER_LOCAL:-local-provider}"
prop_replace 'nifi.state.management.provider.cluster'       "${NIFI_STATE_MANAGEMENT_PROVIDER_CLUSTER:-zk-provider}"
prop_replace 'nifi.state.management.embedded.zookeeper.start' "${NIFI_STATE_MANAGEMENT_EMBEDDED_ZK_START:-true}"
prop_replace 'nifi.state.management.embedded.zookeeper.properties' "${NIFI_STATE_MANAGEMENT_EMBEDDED_ZK_PROPERTIES:-./conf/zookeeper.properties}"

################################
# security properties
################################

if [ -n "${NIFI_SENSITIVE_PROPS_KEY}" ]; then
    prop_replace 'nifi.sensitive.props.key' "${NIFI_SENSITIVE_PROPS_KEY}"
    prop_replace 'nifi.sensitive.props.algorithm' "${NIFI_SENSITIVE_PROPS_ALGO:-NIFI_PBKDF2_AES_GCM_256}"
    prop_replace 'nifi.sensitive.props.provider' "${NIFI_SENSITIVE_PROPS_PROVIDER:-BC}"
fi

. "${scripts_dir}/update_cluster_state_management.sh"

# Check if we are secured or unsecured
case ${AUTH} in
    oidc)
        echo 'Enabling OIDC user authentication'
        . "${scripts_dir}/node-certs.sh"
        . "${scripts_dir}/configure_oidc.sh"
        ;;
    tls)
        echo 'Enabling Two-Way SSL user authentication'
        . "${scripts_dir}/secure.sh"
        ;;
    ldap)
        echo 'Enabling LDAP user authentication'
        # Reference ldap-provider in properties
        export NIFI_SECURITY_USER_LOGIN_IDENTITY_PROVIDER="ldap-provider"

        . "${scripts_dir}/secure.sh"
        . "${scripts_dir}/update_login_providers.sh"
        ;;
esac
#############################
# Update authorizers.xml
#############################
[ -f "${scripts_dir}/update-authorizers.sh" ] && . "${scripts_dir}/update-authorizers.sh"


# Continuously provide logs so that 'docker logs' can produce them
"${NIFI_HOME}/bin/nifi.sh" run &
nifi_pid="$!"
tail -F --pid=${nifi_pid} "${NIFI_HOME}/logs/nifi-app.log" &

trap 'echo Received trapped signal, beginning shutdown...;./bin/nifi.sh stop;exit 0;' TERM HUP INT;
trap ":" EXIT

echo NiFi running with PID ${nifi_pid}.
wait ${nifi_pid}