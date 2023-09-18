#!/bin/bash

# Initialize variables
CLUSTER_NAME=""
ACCOUNT_ID=""
SUBNET_IDS=""

# Parse command-line options
while getopts ":c:a:s:" opt; do
  case $opt in
    c)
      CLUSTER_NAME="$OPTARG"
      ;;
    a)
      ACCOUNT_ID="$OPTARG"
      ;;
    s)
      SUBNET_IDS="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Check if required options are provided
if [ -z "$CLUSTER_NAME" ] || [ -z "$ACCOUNT_ID" ] || [ -z "$SUBNET_IDS" ]; then
  echo "Usage: $0 -c [CLUSTER_NAME] -a [ACCOUNT_ID] -s [SUBNET_IDS]"
  exit 1
fi

# Define other variables
ROLE_NAME="eksClusterRole"
POLICY_ARN="arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

# Create a file for the role trust relationship
cat <<EoF > eks-trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EoF

# Create the IAM role for EKS
aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document file://eks-trust-policy.json

# Attach the AmazonEKSClusterPolicy to the role
aws iam attach-role-policy \
    --policy-arn $POLICY_ARN \
    --role-name $ROLE_NAME

# Create the EKS cluster
aws eks create-cluster \
    --name $CLUSTER_NAME \
    --role-arn arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME \
    --resources-vpc-config subnetIds=$SUBNET_IDS

# Wait for user to confirm that the cluster is active
echo "Please wait for the cluster to become ACTIVE. You can check the status with the following command:"
echo "aws eks describe-cluster --name $CLUSTER_NAME --query \"cluster.status\""
read -p "Press enter to continue once the cluster is ACTIVE..."

# Update kubectl config
aws eks update-kubeconfig --name $CLUSTER_NAME

echo "Cluster setup is complete."

# Clean up
rm -f eks-trust-policy.json
