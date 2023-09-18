# aws-eks-nginx-webserver
Set up a secure, scalable NGINX web server on AWS EKS. Features include AWS Load Balancer, IAM roles, AWS Secrets Manager for environment variables, and adherence to Kubernetes best practices. Designed for high availability and easy management.

# Setup cluster

Run script to setup clsuter
```sh
-a account
-c cluster
-s subnets

```

Example
```sh
./setup-eks-cluster.sh -c my-cluster -a 123456789012 -s subnet-xxxx,subnet-yyyy,subnet-zzzz
```