from unittest import TestCase, mock
import hvac

class TestSecretsClient(TestCase):

    @mock.patch('hvac.Client')
    def test_create_or_update_secret(self, mock_hvac_client):
        # Mock the auth and secrets calls
        mock_client_instance = mock_hvac_client.return_value

        # Mock AWS IAM login
        mock_client_instance.auth.aws.iam_login.return_value = {
            "auth": {"client_token": "test-token"}
        }

        # Mock secret creation
        mock_client_instance.secrets.kv.v2.create_or_update_secret.return_value = {
            "data": {"created_time": "2025-03-12T10:00:00Z"}
        }

        # Sample data for test
        secrets_url = "https://example-vault-url"
        secret_role = "my-role"
        secret_path = "my/secret/path"
        new_keys = {"key1": "value1", "key2": "value2"}
        assumed_role = {
            "Credentials": {
                "AccessKeyId": "test-access-key",
                "SecretAccessKey": "test-secret-key",
                "SessionToken": "test-session-token"
            }
        }

        # Initialize secrets client
        secrets_client = hvac.Client(url=secrets_url, verify=False)

        # Call the AWS IAM login
        secrets_client.auth.aws.iam_login(
            assumed_role["Credentials"]["AccessKeyId"],
            assumed_role["Credentials"]["SecretAccessKey"],
            assumed_role["Credentials"]["SessionToken"],
            role=secret_role
        )

        # Call create_or_update_secret
        result = secrets_client.secrets.kv.v2.create_or_update_secret(
            path=secret_path,
            secret=new_keys
        )

        # Assertions
        mock_client_instance.auth.aws.iam_login.assert_called_once_with(
            "test-access-key", "test-secret-key", "test-session-token", role="my-role"
        )

        mock_client_instance.secrets.kv.v2.create_or_update_secret.assert_called_once_with(
            path="my/secret/path",
            secret={"key1": "value1", "key2": "value2"}
        )

        # Check the result
        self.assertEqual(result["data"]["created_time"], "2025-03-12T10:00:00Z")



import boto3

client = boto3.client('route53')

response = client.create_hosted_zone(
    Name='example.com.',   # Replace with your domain name (must end with a dot)
    CallerReference='unique-string-1234'  # Unique identifier for the request
)

hosted_zone_id = response['HostedZone']['Id']
print(f"Hosted Zone Created: {hosted_zone_id}")





import boto3

client = boto3.client('route53')

response = client.create_hosted_zone(
    Name='example.com.',   # Replace with your domain name (must end with a dot)
    CallerReference='unique-string-1234',  # Unique identifier for the request
    VPC={
        'VPCRegion': 'us-east-1',  # Replace with your VPC region
        'VPCId': 'vpc-12345678'    # Replace with your VPC ID
    },
    HostedZoneConfig={
        'PrivateZone': True
    }
)

hosted_zone_id = response['HostedZone']['Id']
print(f"Private Hosted Zone Created: {hosted_zone_id}")





import boto3

# Initialize the Route53 client
client = boto3.client('route53')

# Define the hosted zone ID
HOSTED_ZONE_ID = 'Z123456789EXAMPLE'

# Define the record details
RECORD_NAME = 'example.yourdomain.com.'
RECORD_TYPE = 'A'
RECORD_VALUE = '192.0.2.44'  # IP address for A record

def create_route53_record():
    response = client.change_resource_record_sets(
        HostedZoneId=HOSTED_ZONE_ID,
        ChangeBatch={
            'Comment': 'Creating A record',
            'Changes': [
                {
                    'Action': 'CREATE',
                    'ResourceRecordSet': {
                        'Name': RECORD_NAME,
                        'Type': RECORD_TYPE,
                        'TTL': 300,  # Time to live in seconds
                        'ResourceRecords': [
                            {
                                'Value': RECORD_VALUE
                            }
                        ]
                    }
                }
            ]
        }
    )
    print(response)

if __name__ == "__main__":
    create_route53_record()






name: Check Terraform Token Expiry

on:
  schedule:
    - cron: '0 0 * * *'  # Runs daily at midnight UTC
  workflow_dispatch:  # Allows manual triggering

jobs:
  check-token-expiry:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Check Terraform Token Expiry
        env:
          TERRAFORM_TOKEN: ${{ secrets.TERRAFORM_TOKEN }}
        run: |
          if [ -z "$TERRAFORM_TOKEN" ]; then
            echo "Terraform token is missing!"
            exit 1
          fi

          # Decode the token to extract expiry (assuming JWT format)
          EXPIRY_TIMESTAMP=$(echo "$TERRAFORM_TOKEN" | jq -R 'split(".") | .[1] | @base64d | fromjson | .exp')
          
          if [ -z "$EXPIRY_TIMESTAMP" ]; then
            echo "Failed to extract expiry timestamp!"
            exit 1
          fi

          CURRENT_TIMESTAMP=$(date +%s)
          EXPIRY_DATE=$(date -d @$EXPIRY_TIMESTAMP +"%Y-%m-%d %H:%M:%S")

          echo "Terraform token expires at: $EXPIRY_DATE"

          if [ "$CURRENT_TIMESTAMP" -ge "$EXPIRY_TIMESTAMP" ]; then
            echo "Terraform token has expired!"
            exit 1
          else
            echo "Terraform token is still valid."
          fi














name: Check Terraform Token Expiry

on:
  schedule:
    - cron: '0 0 * * *'  # Runs every day at midnight UTC
  workflow_dispatch:  # Allows manual trigger

jobs:
  check-token-expiry:
    runs-on: ubuntu-latest

    steps:
      - name: Check Terraform Token Expiry
        env:
          TF_API_TOKEN: ${{ secrets.TF_API_TOKEN }}
        run: |
          if [ -z "$TF_API_TOKEN" ]; then
            echo "Terraform API token is missing!"
            exit 1
          fi

          # Query Terraform Cloud API for token details
          RESPONSE=$(curl -s -H "Authorization: Bearer $TF_API_TOKEN" \
                             -H "Content-Type: application/json" \
                             "https://app.terraform.io/api/v2/account/details")

          # Extract expiry date
          EXPIRY_DATE=$(echo "$RESPONSE" | jq -r '.data.attributes.token.expired_at')

          if [ "$EXPIRY_DATE" == "null" ]; then
            echo "Could not retrieve token expiry date."
            exit 1
          fi

          echo "Terraform API Token expires on: $EXPIRY_DATE"

          # Convert expiry date to Unix timestamp
          EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
          CURRENT_TIMESTAMP=$(date +%s)

          # Check if the token is expired or about to expire (within 3 days)
          if [ "$CURRENT_TIMESTAMP" -ge "$EXPIRY_TIMESTAMP" ]; then
            echo "Terraform token has expired!"
            exit 1
          elif [ $((EXPIRY_TIMESTAMP - CURRENT_TIMESTAMP)) -le 259200 ]; then
            echo "Warning: Terraform token will expire in less than 3 days!"
            exit 1
          else
            echo "Terraform token is still valid."
          fi














name: Check Terraform Token Expiry

on:
  schedule:
    - cron: '0 0 * * *'  # Runs daily at midnight UTC
  workflow_dispatch:  # Allows manual trigger

jobs:
  check-token-expiry:
    runs-on: ubuntu-latest

    steps:
      - name: Check Terraform Token Expiry
        env:
          TF_API_TOKEN: ${{ secrets.TF_API_TOKEN }}
          TF_ORG_NAME: "your-terraform-org"  # Replace with your org name
        run: |
          if [ -z "$TF_API_TOKEN" ]; then
            echo "Terraform API token is missing!"
            exit 1
          fi

          # Query Terraform Cloud API for team token details
          RESPONSE=$(curl -s -H "Authorization: Bearer $TF_API_TOKEN" \
                             -H "Content-Type: application/json" \
                             "https://app.terraform.io/api/v2/organizations/$TF_ORG_NAME/team-tokens")

          # Extract expiry date from response
          EXPIRY_DATE=$(echo "$RESPONSE" | jq -r '.data[].attributes.expired-at')

          if [ "$EXPIRY_DATE" == "null" ]; then
            echo "Could not retrieve token expiry date."
            exit 1
          fi

          echo "Terraform Team Token expires on: $EXPIRY_DATE"

          # Convert expiry date to Unix timestamp
          EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
          CURRENT_TIMESTAMP=$(date +%s)

          # Calculate days left before expiry
          DAYS_LEFT=$(( (EXPIRY_TIMESTAMP - CURRENT_TIMESTAMP) / 86400 ))

          echo "Days left until token expiry: $DAYS_LEFT"

          # Trigger alert if token is expiring in 10 days or less
          if [ "$DAYS_LEFT" -le 10 ]; then
            echo "⚠️ Warning: Terraform token will expire in $DAYS_LEFT days! ⚠️"
            exit 1
          else
            echo "✅ Terraform token is still valid."
          fi

          fi



https://developer.hashicorp.com/terraform/cloud-docs/api-docs/team-tokens#show-a-team-token






name: Check Terraform User Token Expiry

on:
  schedule:
    - cron: '0 0 * * *'  # Runs daily
  workflow_dispatch:  # Allow manual trigger

jobs:
  check-token-expiry:
    runs-on: ubuntu-latest

    steps:
      - name: Check Terraform User Token Expiry
        env:
          TF_API_TOKEN: ${{ secrets.TF_API_TOKEN }}
          TF_TOKEN_ID: ${{ secrets.TF_TOKEN_ID }}
        run: |
          if [ -z "$TF_API_TOKEN" ] || [ -z "$TF_TOKEN_ID" ]; then
            echo "Terraform API token or Token ID is missing!"
            exit 1
          fi

          # Query Terraform Cloud API for token details
          RESPONSE=$(curl -s -H "Authorization: Bearer $TF_API_TOKEN" \
                             -H "Content-Type: application/json" \
                             "https://app.terraform.io/api/v2/authentication-tokens/$TF_TOKEN_ID")

          # Extract expiry date
          EXPIRY_DATE=$(echo "$RESPONSE" | jq -r '.data.attributes.expired-at')

          if [ "$EXPIRY_DATE" == "null" ]; then
            echo "Could not retrieve token expiry date. Check permissions."
            exit 1
          fi

          echo "Terraform User Token expires on: $EXPIRY_DATE"

          # Convert expiry date to Unix timestamp
          EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
          CURRENT_TIMESTAMP=$(date +%s)

          # Calculate days left before expiry
          DAYS_LEFT=$(( (EXPIRY_TIMESTAMP - CURRENT_TIMESTAMP) / 86400 ))

          echo "Days left until token expiry: $DAYS_LEFT"

          # Trigger alert if token is expiring in 10 days or less
          if [ "$DAYS_LEFT" -le 10 ]; then
            echo "⚠️ Warning: Terraform token will expire in $DAYS_LEFT days! ⚠️"
            exit 1
          else
            echo "✅ Terraform token is still valid."
          fi



curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request GET \
  https://app.terraform.io/api/v2/users/user-1Hv8xv92iNBgrR2D/authentication-tokens | jq '.data[0].attributes | {expired_at: .["expired-at"], description: .description}'





# Convert expiration date to seconds since epoch
expired_seconds=$(date -d "$expired_at" +%s)

# Get the current time in seconds
current_seconds=$(date +%s)

# Calculate the difference in days
diff_days=$(( (expired_seconds - current_seconds) / 86400 ))

# Check if within 10 days
if [ "$diff_days" -le 10 ] && [ "$diff_days" -ge 0 ]; then
    echo "Expired within 10 days"
else
    echo "Not expiring within 10 days"
fi











- name: Publish success message to SNS
  run: |
    if [ ${{ job.status }} == 'success' ]; then
      aws sns publish \
        --topic-arn ${{ secrets.SNS_TOPIC_ARN }} \
        --message "The GitHub Actions workflow completed successfully!" \
        --subject "GitHub Actions Success Notification"
    else
      aws sns publish \
        --topic-arn ${{ secrets.SNS_TOPIC_ARN }} \
        --message "The GitHub Actions workflow failed." \
        --subject "GitHub Actions Failure Notification"
    fi





import boto3
import json
from botocore.exceptions import ClientError

def create_secret(secret_name, role_name=None, region_name='us-east-1'):
    secret_value = json.dumps({'value': 'abc'})

    # Function to assume a role
    def assume_role(role_arn):
        sts_client = boto3.client('sts')
        response = sts_client.assume_role(
            RoleArn=role_arn,
            RoleSessionName='AssumeRoleSession'
        )
        creds = response['Credentials']
        return {
            'aws_access_key_id': creds['AccessKeyId'],
            'aws_secret_access_key': creds['SecretAccessKey'],
            'aws_session_token': creds['SessionToken']
        }

    # Determine the client to use
    if role_name:
        # Construct full role ARN (modify this if your role is in another account or path is different)
        account_id = boto3.client('sts').get_caller_identity().get('Account')
        role_arn = f'arn:aws:iam::{account_id}:role/{role_name}'
        assumed_creds = assume_role(role_arn)
        client = boto3.client('secretsmanager', region_name=region_name, **assumed_creds)
    else:
        client = boto3.client('secretsmanager', region_name=region_name)

    # Create the secret
    try:
        response = client.create_secret(
            Name=secret_name,
            SecretString=secret_value,
            Description='Secret created via script'
        )
        print(f"Secret {secret_name} created successfully.")
        return response
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceExistsException':
            print(f"Secret {secret_name} already exists.")
        else:
            print(f"Error creating secret: {e}")
        return None






import os
import unittest
from unittest.mock import patch

def get_secret_name():
    return os.environ.get('PRD_SECRET_NAME')

class TestSecretEnv(unittest.TestCase):
    @patch.dict(os.environ, {'PRD_SECRET_NAME': 'mocked-secret-name'})
    def test_get_secret_name(self):
        secret_name = get_secret_name()
        self.assertEqual(secret_name, 'mocked-secret-name')

if __name__ == '__main__':
    unittest.main()










class TestTerraformToken(unittest.TestCase):
    @patch('requests.post')
    def test_get_token(self, mock_post):
        # Mock response structure
        mock_response = Mock()
        mock_response.json.return_value = {
            'data': {
                'attributes': {
                    'token': 'mocked-token'
                }
            }
        }
        mock_post.return_value = mock_response

        # Call your function
        token = get_token('https://dummy.url', headers={})

        # Assert the result
        self.assertEqual(token, 'mocked-token')


















provider "aws" {
  region = "us-east-1"
}

# Replace with your VPC ID and optionally subnet ID
variable "vpc_id" {
  default = "vpc-xxxxxxxx"
}

resource "aws_security_group" "tfc_agent_sg" {
  name        = "tfc-agent-sg"
  description = "Allow outbound HTTPS and optional SSH"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["your-ip/32"] # Replace with your IP if needed for SSH
  }
}

resource "aws_instance" "tfc_agent" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI in us-east-1
  instance_type = "t3.micro"
  subnet_id     = "subnet-xxxxxxxx"       # Add your subnet ID here
  key_name      = "your-key-name"         # Optional

  vpc_security_group_ids = [aws_security_group.tfc_agent_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -aG docker ec2-user
              docker run -d \\
                --name=tfc-agent \\
                -e TFC_AGENT_TOKEN=<your-agent-token> \\
                -e TFC_AGENT_NAME="ec2-agent" \\
                hashicorp/tfc-agent:latest
              EOF

  tags = {
    Name = "Terraform Cloud Agent"
  }
}


