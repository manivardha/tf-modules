#!/bin/bash

# mas_docgen_user_data.sh is in masapps/docgen and is updated per-environment (e.g. EFS ID)
# by the pipeline. It creates the Oracle user, installs/configures CWA, etc.
# then starts "bitools" to run DocGen

# Use the Amazon IMDSv2 service to retrieve information about this instance
token=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
instance_id=$(curl -s -H "X-aws-ec2-metadata-token: ${token}" http://169.254.169.254/latest/meta-data/instance-id)
environment=$(aws --output=text ec2 describe-tags --region us-east-1 --filters Name=resource-id,Values="$instance_id" --query "Tags[?Key == 'environment'].Value")
lower_env=${environment,,}
aws s3 cp s3://mas"$lower_env"config/docgen/mas_docgen_user_data.sh /var/tmp/
chmod +x /var/tmp/mas_docgen_user_data.sh
bash /var/tmp/mas_docgen_user_data.sh