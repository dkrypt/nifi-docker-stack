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
if [ -n "$SECURITY_USER_OIDC_DISCOVERY_URL" ] ;
then
    prop_replace 'nifi.security.user.oidc.discovery.url' "${SECURITY_USER_OIDC_DISCOVERY_URL:-}"
    prop_replace 'nifi.security.user.oidc.connect.timeout' "${SECURITY_USER_OIDC_CONNECT_TIMEOUT:-10 secs}"
    prop_replace 'nifi.security.user.oidc.read.timeout' "${SECURITY_USER_OIDC_READ_TIMEOUT:-10 secs}"
    prop_replace 'nifi.security.user.oidc.client.id' "${SECURITY_USER_OIDC_CLIENT_ID:-}"
    prop_replace 'nifi.security.user.oidc.client.secret' "${SECURITY_USER_OIDC_CLIENT_SECRET:-}"
    prop_replace 'nifi.security.user.oidc.preferred.jwsalgorithm' "${SECURITY_USER_OIDC_JWS_ALGO:-}"
    prop_replace 'nifi.security.user.oidc.additional.scopes' "${SECURITY_USER_OIDC_SCOPES:-email}"
fi