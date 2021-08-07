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

cd ${NIFI_HOME}/conf

initial_admin_identity=${INITAL_ADMIN_IDENTITY}
node_identities=${NODE_IDENTITIES}
# Trim start/end for removing white spaces
node_identities=$(echo $node_identities | tr -d ' ')
# write the initial admin first and add the first node identity
xmlstarlet ed --inplace -u "authorizers/userGroupProvider/property[@name='Initial User Identity 1']" -v "${initial_admin}" ${NIFI_HOME}/conf/authorizers.xml
xmlstarlet ed --inplace -u "authorizers/accessPolicyProvider/property[@name='Initial Admin Identity']" -v "${initial_admin}" ${NIFI_HOME}/conf/authorizers.xml

# write initial users and node identities
id=1
for identity in $(echo $node_identities | sed "s/,/ /g")
do
    id_dn="CN=${identity}, OU=NIFI"
    xmlstarlet ed --inplace -a "authorizers/userGroupProvider/property[@name='Initial User Identity ${id}']" -t elem -n property -v "${id_dn}" ${NIFI_HOME}/conf/authorizers.xml
    xmlstarlet ed --inplace -u "authorizers/accessPolicyProvider/property[@name='Node Identity ${id}']" -v "${id_dn}" ${NIFI_HOME}/conf/authorizers.xml
    xmlstarlet ed --inplace -a "authorizers/accessPolicyProvider/property[@name='Node Identity ${id}']" -t elem -n property -v "dummy" ${NIFI_HOME}/conf/authorizers.xml
    id=$((id+1))
    xmlstarlet ed --inplace -i "authorizers/userGroupProvider/property[text() = '${id_dn}']" -t attr -n name -v "Initial User Identity ${id}" ${NIFI_HOME}/conf/authorizers.xml
    xmlstarlet ed --inplace -i "authorizers/accessPolicyProvider/property[text() = 'dummy']" -t attr -n name -v "Node Identity ${id}" ${NIFI_HOME}/conf/authorizers.xml
done

# delete the additional element that is not needed
xmlstarlet ed --inplace -d "authorizers/accessPolicyProvider/property[text() = 'dummy']" ${NIFI_HOME}/conf/authorizers.xml
