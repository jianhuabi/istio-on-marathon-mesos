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

As of ver1.0.5, we can't use it to support mTLS on Istio marathon project. We we can do otherwise is to follow Citadel on K8S design initiative and make some compermise to enable mTLS on Istio marathon.

Citadel on K8S with Istio v1.0.5 is the entity list and watch apiserver primarily for namespaces resources. For each namespace, it prepares **self-signed** (if it is enabled by cmd parameter as --self-signed-ca=true) certs bundle `[root-cert.pem, cert-chain.pem, key.pem]` and saves it as secrets `(istio.default)` in apiserver for this namespace.

Upon receving POD creation by apiserver, if this POD is mutated by Istio kube-inject, the injected istio-proxy sidecar requires to mount secret of `istio.default` to `/etc/certs` folder for istio-proxy to consume. 

Up to this point, Envoy which is buddied with this workload is ready to enable mTLS upon mesh policy at Istio control plane. 

## Enable mTLS for service or app running on Istio mesh L7 overlay

