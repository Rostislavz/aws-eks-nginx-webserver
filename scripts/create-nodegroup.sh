#!/bin/bash

# Define usage of the script
usage() {
  echo "Usage: $0 -c <cluster_name> -g <nodegroup_name> -s <subnet_ids>"
  exit 1
}

# Parse command line options
while getopts "c:g:s:" option; do
  case "${option}" in
    c) CLUSTER_NAME=${OPTARG};;
    g) NODEGROUP_NAME=${OPTARG};;
    s ) # Subnets
      IFS=',' read -ra SUBNET_IDS <<< "$OPTARG"
      ;;
    *) usage;;
  esac
done

# Validate that all options are provided
if [ -z "${CLUSTER_NAME}" ] || [ -z "${NODEGROUP_NAME}" ] || [ -z "${SUBNET_IDS}" ]; then
  usage
fi

# Create IAM role for node group
ROLE_NAME="eks-${NODEGROUP_NAME}-role"
echo "Creating IAM Role for Node Group..."

# Create the assume role policy using a heredoc
read -r -d '' ASSUME_ROLE_POLICY_JSON << EOM
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": ["eks.amazonaws.com", "ec2.amazonaws.com"]},
      "Action": "sts:AssumeRole"
    }
  ]
}
EOM

# Create the role using the embedded JSON
aws iam create-role --role-name ${ROLE_NAME} --assume-role-policy-document "${ASSUME_ROLE_POLICY_JSON}"
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy --role-name ${ROLE_NAME}
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy --role-name ${ROLE_NAME}
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly --role-name ${ROLE_NAME}

# Get the Role ARN
ROLE_ARN=$(aws iam get-role --role-name ${ROLE_NAME} --query 'Role.Arn' --output text)

# Create Node Group
echo "Creating EKS Node Group..."
aws eks create-nodegroup \
    --cluster-name ${CLUSTER_NAME} \
    --nodegroup-name ${NODEGROUP_NAME} \
    --scaling-config minSize=1,maxSize=3,desiredSize=1 \
    --instance-type t3.medium \
    --ami-type AL2_x86_64 \
    --node-role ${ROLE_ARN} \
    --subnets ${SUBNET_IDS}

echo "Node group ${NODEGROUP_NAME} is being created in cluster ${CLUSTER_NAME}..."
