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

[ -f "${scripts_dir}/common.sh" ] && . "${scripts_dir}/common.sh"

################################
# Modify zookeeper.properties
################################
prop_replace 'initLimit' "10"                       ${zookeeper_props_file}
prop_replace 'autopurge.purgeInterval' "24"         ${zookeeper_props_file}
prop_replace 'syncLimit' "5"                        ${zookeeper_props_file}
prop_replace 'tickTime' "2000"                      ${zookeeper_props_file}
prop_replace 'dataDir' "./state/zookeeper"          ${zookeeper_props_file}
prop_replace 'autopurge.snapRetailCount' "30"       ${zookeeper_props_file}
prop_replace 'server.1' "localhost:2888:3888;2181"  ${zookeeper_props_file}

################################
# Create myid file
################################
cd ${NIFI_HOME}
mkdir -p state/zookeeper
echo "1" > ./state/zookeeper/myid
