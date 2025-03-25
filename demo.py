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
