#!/bin/bash

set -e

echo "Sending SSM command..."
COMMAND_ID=$(aws ssm send-command \
  --document-name "${DOCUMENT_NAME}" \
  --targets "[{\"Key\":\"instanceIds\",\"Values\":[\"${INSTANCE_ID}\"]}]" \
  --parameters "{\"branch\":[\"${CI_COMMIT_REF_NAME}\"],\"application\":[\"backend\"],\"imagename\":[\"${IMAGE_NAME}\"],\"imagetag\":[\"${IMAGE_TAG}\"]}" \
  --region "${AWS_DEFAULT_REGION}" \
  --query "Command.CommandId" \
  --output text)

echo "Command sent successfully. Command ID: ${COMMAND_ID}"

echo "Waiting for SSM command to execute..."

until aws ssm wait command-executed --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" --region "$AWS_DEFAULT_REGION"; do
    echo "Waiter timed out (100s), but command is likely still InProgress. Restarting waiter..."
done

echo "Fetching final command execution results..."
aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --region "$AWS_DEFAULT_REGION"