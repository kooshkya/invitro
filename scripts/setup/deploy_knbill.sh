#!/usr/bin/env bash
#
# MIT License
#
# Copyright (c) 2023 EASL and the vHive community
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

MASTER_NODE=$1

server_exec() { 
    ssh -oStrictHostKeyChecking=no -p 22 $MASTER_NODE "$1"
    if [ $? -ne 0 ]; then
        echo "ERROR: Command failed: $1"
        exit 1
    fi
}

{
    echo 'Setting up KnBill components'
    
    server_exec "kubectl patch configmap -n knative-serving config-observability \
        --type='merge' \
        -p '{\"data\": {\"logging.enable-request-log\": \"true\"}}'"

    server_exec "kubectl patch configmap -n knative-serving config-observability \
        --type='merge' \
        -p '{\"data\": {\"logging.request-log-template\": \"{\\\"httpRequest\\\": {\\\"requestMethod\\\": \\\"{{.Request.Method}}\\\", \\\"requestUrl\\\": \\\"{{js .Request.RequestURI}}\\\", \\\"requestSize\\\": \\\"{{.Request.ContentLength}}\\\", \\\"status\\\": {{.Response.Code}}, \\\"responseSize\\\": \\\"{{.Response.Size}}\\\", \\\"userAgent\\\": \\\"{{js .Request.UserAgent}}\\\", \\\"remoteIp\\\": \\\"{{js .Request.RemoteAddr}}\\\", \\\"serverIp\\\": \\\"{{.Revision.PodIP}}\\\", \\\"referer\\\": \\\"{{js .Request.Referer}}\\\", \\\"latency\\\": \\\"{{.Response.Latency}}s\\\", \\\"protocol\\\": \\\"{{.Request.Proto}}\\\"}, \\\"traceId\\\": \\\"{{index .Request.Header \\\"X-B3-Traceid\\\"}}\\\"}\"}}'"

    # kubectl create/apply with error check
    server_exec "kubectl create namespace logging"
    server_exec "kubectl create -f https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/fluent-bit-service-account.yaml"
    server_exec "kubectl create -f https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/fluent-bit-role.yaml"
    server_exec "kubectl create -f https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/fluent-bit-role-binding.yaml"
    server_exec "kubectl apply -f https://raw.githubusercontent.com/kooshkya/invitro/refs/heads/kooshkya/knbill/config/fluent-bit-collector.yaml"
    server_exec "kubectl apply -f https://raw.githubusercontent.com/kooshkya/invitro/refs/heads/kooshkya/knbill/config/fluent-bit-configmap.yaml"
    server_exec "kubectl apply -f https://raw.githubusercontent.com/kooshkya/invitro/refs/heads/kooshkya/knbill/config/fluent-bit-ds.yaml"

    echo 'Done setting up KnBill components'

    exit
}

