# istio-on-marathon-mesos

## Quick Start on DC/OS

1. Deploy etcd, apiserver, pilot, zipkin in DC/OS. 
You can deploy those app through UI, or using command-line.
```
dcos marathon app add install/etcd.json
dcos marathon app add install/zipkin.json
dcos marathon app add install/apiserver.json
dcos marathon app add install/pilot.json
```

2. Deploy the bookfinfo sample

```
dcos marathon pod add bookinfo/details.json
dcos marathon pod add bookinfo/ratings.json
dcos marathon pod add bookinfo/reviews-v1.json
dcos marathon pod add bookinfo/reviews-v2.json
dcos marathon pod add bookinfo/reviews-v3.json
dcos marathon pod add bookinfo/productpage.json
```

3. Now you can visit the productpage! 

Visit `$HOST_IP_OF_PRODUCTPAGE:$HOST_PORT_OF_PRODUCTPAGE`
You can refresh the page and find Book Reviews has three kinds of version. This is because the envoy proxy of `productpage` pod will do round-roubin load-balance to one of the 3 `reviews` pods when there is NO routing rules applied.

4. Use kubectl to apply routing rules.
In the master or any agent node:
```
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.7.3/bin/linux/amd64/kubectl && export PATH=$PATH:$PWD && chmod +x kubectl
kubectl config set-context istio --cluster=istio
kubectl config set-cluster istio --server=http://apiserver.marathon.autoip.dcos.thisdcos.directory:10080
kubectl config use-context istio
```
* Routing all traffics to v1
```
kubectl apply -f bookinfo/vs-all-v1.yaml
```
Now you can visit `productpage` again and find the `reviews` is always v1.

* Fault inject: delaying requests to `details`
```
kubectl apply -f bookinfo/vs-delay-details.yaml
```
Now you can login as `jason` and found the page loading is slow... 

```
# kubectl get virtualservice details
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: details
spec:
  hosts:
  - details.marathon.l4lb.thisdcos.directory
  http:
  - match:
    - headers:
        end-user:
          exact: jason
    fault:
      delay:
        percent: 100
        fixedDelay: 7s
    route:
    - destination:
        host: details.marathon.l4lb.thisdcos.directory
        subset: v1
  - route:
    - destination:
        host: details.marathon.l4lb.thisdcos.directory
        subset: v1
```
It inject 7s delay when routing to `details` service. 

* Fault inject: aborting rules
```
kubectl apply -f bookinfo/vs-details-abort.yaml
```
Refresh the `productpage` and visit `zipkin`. You can find tracing information that the return `status code` of `details` is `500`



## How to run Istio on Marathon/Mesos

WIP

## Code
https://github.com/harryge00/istio/tree/marathon-pilot/pilot/pkg/serviceregistry/mesos