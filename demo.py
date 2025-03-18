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
