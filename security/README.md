# How to enable mutual TLS on Istio on marathon mesos

This article covers the primary activities you might need to perform when enabling, configuring, and using Istio authentication policies. Find out more about the underlying concepts in the [authentication overview](https://istio.io/docs/concepts/security/#authentication).

Following activities are made with assumpition of Istio v1.0.5. 

## Istio mTLS architecture (under development)

![Istio mTLS Arch](https://istio.io/docs/concepts/security/node_agent.svg)

The flow goes as follows:

1. Citadel creates a gRPC service to take CSR requests.

2. Envoy sends a certificate and key request via Envoy secret discovery service (SDS) API.

3. Upon receiving the SDS request, node agent creates the private key and CSR, and sends the CSR with its credentials to Citadel for signing.

4. Citadel validates the credentials carried in the CSR, and signs the CSR to generate the certificate.

5. The node agent sends the certificate received from Citadel and the private key to Envoy, via the Envoy SDS API.

The above CSR process repeats periodically for certificate and key rotation.

### Limitation of Istio mTLS architecture at V1.0.5

According to Istio offical website, the forementioned architecture will be applicable on Istio with or w/o K8S. The first Istio version to support this architecture is supposely availabe at v1.1. 

As of ver1.0.5, we can't use it to support mTLS on Istio marathon project. We can do otherwise is to follow Citadel on K8S design initiative and make some compermise to enable mTLS on Istio marathon.

Citadel on K8S with Istio v1.0.5 is the entity list and watch apiserver primarily for namespaces resources. For each namespace, it prepares **self-signed** (if it is enabled by cmd parameter as --self-signed-ca=true) certs bundle `[root-cert.pem, cert-chain.pem, key.pem]` and saves it as secrets `(istio.default)` in apiserver for this namespace.

Upon receving POD creation by apiserver, if this POD is mutated by Istio kube-inject, the injected istio-proxy sidecar requires to mount secret of `istio.default` to `/etc/certs` folder for istio-proxy to consume. 

Up to this point, Envoy which is buddied with this workload is ready to enable mTLS upon mesh policy at Istio control plane. 

## Citadel on Marathon/Mesos Deployment Quick Start 

1. Follow [this page](https://github.com/harryge00/istio-on-marathon-mesos/blob/master/README.md) to deploy Istio on Marathon/Mesos

2. Install `Citadel` with below command. 
```bash
dcos marathon app add install/citadel.json
```

3. The workload certs bundle is downloadable from [aws s3](https://s3-ap-southeast-1.amazonaws.com/marathon-cmd/bundle-certs.tgz)

4. In order to test and validate Istio mTLS, we need to deploy two workloads `httpbin` `sleep` to Istio Mesh referenced from Istio offical testing suit. 

```bash
dcos marathon pod add httpbin/httpbin.json
dcos marathon pod add httpbin/sleep.json
```

## Enable mTLS for service or app running on Istio mesh L7 overlay

1. Verify HTTP connectivity between `sleep` app and `httpbin` app deployed previously

Login to dcos *sleep* task to test connectivity from `sleep` to `httpbin`

```sh
dcos task |grep sleep

proxy  10.0.3.2     root     R    sleep.instance-8d1e6ccb-26dd-11e9-8e21-0a358f970c47.proxy                                        8c6e332d-0e16-4239-b82c-b51f51465f5a-S4  aws/us-west-2  aws/us-west-2c
sleep  10.0.3.2     root     R    sleep.instance-8d1e6ccb-26dd-11e9-8e21-0a358f970c47.sleep                                        8c6e332d-0e16-4239-b82c-b51f51465f5a-S4  aws/us-west-2  aws/us-west-2c

dcos task exec -it sleep.instance-8d1e6ccb-26dd-11e9-8e21-0a358f970c47.sleep sh
```
```sh
root@8c6e332d# curl -s http://httpbin.marathon.l4lb.thisdcos.directory:8000/ip -s -o /dev/null -w "from sleep to httpbin: %{http_code}\n"

from sleep to httpbin: 200
```

2. Globally enabling Istio mutual TLS

You could use below utility dcos task to access apiserver or to use marathon-lb which also dose the job. 

```bash
dcos marathon app add httpbin/kubectl.json
```
```sh
dcos task exec -it [kubectl.cdb36089-26e2-11e9-8e21-0a358f970c47] bash # replace container/taskid with your own ID

> export PATH=$PATH:$PWD
> kubectl get cs

NAME                 STATUS      MESSAGE                                                                                        ERROR
scheduler            Unhealthy   Get http://127.0.0.1:10251/healthz: dial tcp 127.0.0.1:10251: getsockopt: connection refused
controller-manager   Unhealthy   Get http://127.0.0.1:10252/healthz: dial tcp 127.0.0.1:10252: getsockopt: connection refused
etcd-0               Healthy     {"health":"true"}
```
So long as `etc-0` is ready, the we are good to go. 

```bash
cat <<EOF | kubectl apply -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "MeshPolicy"
metadata:
  name: "default"
spec:
  peers:
  - mtls: {}
EOF

meshpolicy "default" created
```

3. Verify mTLS is enabled for all workloads on Istio marathon/mesos Mesh

```sh
root@8c6e332d# curl -s http://httpbin.marathon.l4lb.thisdcos.directory:8000/ip -s -o /dev/null -w "from sleep to httpbin: %{http_code}\n"

from sleep to httpbin: 503
```

4. Setup `DestinationRule` to configure Envoy using mTLS.

```sh
cat <<EOF | kubectl apply -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "default"
  namespace: "default"
spec:
  host: "*.marathon.l4lb.thisdcos.directory"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF

destinationrule "default" created
```

5. Verify `sleep` app now is able to access `httpbin` again via mTLS

```sh
/mnt/mesos/sandbox # curl -s http://httpbin.marathon.l4lb.thisdcos.directory:8000/ip -s -o /dev/null -w "from sleep to httpbin: %{http_code}\n"

from sleep to httpbin: 200
```

you should clean up environment after done the practice. 

## TODO

I will integrate `node-agent` *SDS API* with Envoy when it is ready from Istio community. 
