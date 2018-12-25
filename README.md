# istio-on-marathon-mesos

## How to run Istio on DC/OS

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
WIP. May need to run productpage in public node or Edge-lb.

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
* Fault inject: delaying requests to `details`
```
kubectl apply -f bookinfo/vs-all-v1.yaml
```
Now you can login as `jason` and found the page loading is slow...

## How to run Istio on Marathon/Mesos

WIP

## Code
https://github.com/harryge00/istio/tree/marathon-pilot/pilot/pkg/serviceregistry/mesos