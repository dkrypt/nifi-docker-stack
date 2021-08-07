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

default_hostname=$(hostname -f)
node_certs_dir=${NIFI_NODE_CERTS_DIR:-${NIFI_HOME}/node-certs}
mkdir -p ${node_certs_dir}
cd ${node_certs_dir}
config_dir=$(pwd)

if [ -d $config_dir ] && [ -e ${config_dir}/config.json ]
then
    echo 'config.json found. Generating certs using it...'
    ${NIFI_TOOLKIT_HOME}/bin/tls-toolkit.sh client \
    --useConfigJson \
    --configJsonIn "${config_dir}/config.json" \
    --configJson "${config_dir}/config.json"
else
    echo 'No config.json found. Will create one.'
    ${NIFI_TOOLKIT_HOME}/bin/tls-toolkit.sh client \
    -c ${NIFI_CA_SERVER_HOST:-"nifi-ca"} \
    -p ${NIFI_CA_SERVER_PORT:-9999} \
    -D "CN=${default_hostname}, OU=NIFI" \
    -t ${NIFI_CA_TOKEN} \
    --subjectAlternativeNames "${CA_SANS:-$default_hostname}"
fi

echo 'Successfully generate client certs for NiFi node(s) from CA running at ${CA_SERVER_HOST}:${CA_SERVER_PORT}'
echo 'Updating nifi.properties file to use these certs.'

if [ -f "${config_dir}/config.json" ];
then
    CERT_DN=$(cat ./config.json | jq -r '.dn')
    KEYSTORE_FILE=$(cat ./config.json | jq -r '.keyStore')
    KEYSTORE_TYPE=$(cat ./config.json | jq -r '.keyStoreType')
    KEYSTORE_PASSWORD=$(cat ./config.json | jq -r '.keyStorePassword')
    KEY_PASSWORD=$(cat ./config.json | jq -r '.keyPassword')
    TRUSTSTORE_FILE=$(cat ./config.json | jq -r '.trustStore')
    TRUSTSTORE_TYPE=$(cat ./config.json | jq -r '.trustStoreType')
    TRUSTSTORE_PASSWORD=$(cat ./config.json | jq -r '.trustStorePassword')
fi

[ -f "${scripts_dir}/common.sh" ] && . "${scripts_dir}/common.sh"

prop_replace 'nifi.security.keystore'           "${config_dir}/${KEYSTORE_FILE}"
prop_replace 'nifi.security.keystoreType'       "${KEYSTORE_TYPE}"
prop_replace 'nifi.security.keystorePasswd'     "${KEYSTORE_PASSWORD}"
prop_replace 'nifi.security.keyPasswd'          "${KEY_PASSWORD}"
prop_replace 'nifi.security.truststore'         "${config_dir}/${TRUSTSTORE_FILE}"
prop_replace 'nifi.security.truststoreType'     "${TRUSTSTORE_TYPE}"
prop_replace 'nifi.security.truststorePasswd'   "${TRUSTSTORE_PASSWORD}"
prop_replace 'nifi.security.user.authorizer'    "managed-authorizer"
prop_replace 'nifi.security.allow.anonymous.authentication' "false"

cd ${NIFI_HOME}