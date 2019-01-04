curl -XDELETE http://34.219.234.245:8080/v2/pods/reviews
curl -XDELETE http://34.219.234.245:8080/v2/pods/reviews-v2
curl -XDELETE http://34.219.234.245:8080/v2/pods/reviews-v3
curl -XDELETE http://34.219.234.245:8080/v2/pods/details
curl -XDELETE http://34.219.234.245:8080/v2/pods/productpage
curl -XDELETE http://34.219.234.245:8080/v2/pods/ratings

INNER_NODES="
172.31.22.103
172.31.27.226
172.31.17.24
172.31.26.199
"
for node in $INNER_NODES; do
#statements
echo $node
ssh ec2-user@$node "sudo systemctl restart mesos-slave"
done

curl -XPOST http://34.219.234.245:8080/v2/pods -d @/Users/taozi/coding/istio-yamls/pod-istio/bookinfo-mesos/details.json --header "Content-Type: application/json"
curl -XPOST http://34.219.234.245:8080/v2/pods -d @/Users/taozi/coding/istio-yamls/pod-istio/bookinfo-mesos/ratings.json --header "Content-Type: application/json"
curl -XPOST http://34.219.234.245:8080/v2/pods -d @/Users/taozi/coding/istio-yamls/pod-istio/bookinfo-mesos/productpage.json --header "Content-Type: application/json"
curl -XPOST http://34.219.234.245:8080/v2/pods -d @/Users/taozi/coding/istio-yamls/pod-istio/bookinfo-mesos/reviews-v1.json --header "Content-Type: application/json"
curl -XPOST http://34.219.234.245:8080/v2/pods -d @/Users/taozi/coding/istio-yamls/pod-istio/bookinfo-mesos/reviews-v2.json --header "Content-Type: application/json"
curl -XPOST http://34.219.234.245:8080/v2/pods -d @/Users/taozi/coding/istio-yamls/pod-istio/bookinfo-mesos/reviews-v3.json --header "Content-Type: application/json"