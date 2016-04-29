#!/bin/sh
aws ec2 run-instances \
    --region us-east-1 \
    --image-id ami-67a3a90d \
    --key-name ecs-default \
    --security-group-ids your security group \
    --instance-type c4.2xlarge \
    --subnet-id your subnet id \
    --iam-instance-profile Name=ecs-default-ec2-role \
    --count 1 \
    --user-data file://user-data.txt
