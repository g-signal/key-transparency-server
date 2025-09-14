

import json
import boto3
import base64
from datetime import datetime

kinesis = boto3.client('kinesis')

def lambda_handler(event, context):
    """
    Process Signal_Accounts DynamoDB stream records and forward to Kinesis
    KT Server expects accountPair format: {prev: account, next: account}
    """
    records = []

    for record in event['Records']:
        if record['eventName'] in ['INSERT', 'MODIFY', 'REMOVE']:
            # Extract account data and convert to KT Server format
            prev_account = None
            next_account = None

            print(f"eventName " + record['eventName'])
            if record['eventName'] == 'INSERT':
                # New account registration
                next_account = extract_account_data(record['dynamodb'].get('NewImage', {}))
            elif record['eventName'] == 'REMOVE':
                # Account deletion
                prev_account = extract_account_data(record['dynamodb'].get('OldImage', {}))
            elif record['eventName'] == 'MODIFY':
                # Account update (phone number, username, identity key changes)
                prev_account = extract_account_data(record['dynamodb'].get('OldImage', {}))
                next_account = extract_account_data(record['dynamodb'].get('NewImage', {}))

            # Create accountPair format expected by KT Server
            account_pair = {
                'prev': prev_account,
                'next': next_account
            }

            print(account_pair)

            records.append({
                'Data': json.dumps(account_pair),
                'PartitionKey': get_partition_key(next_account or prev_account)
            })

    if records:
        # Send to Kinesis in batches
        batch_size = 500
        for i in range(0, len(records), batch_size):
            batch = records[i:i + batch_size]

            response = kinesis.put_records(
                StreamName='signal-kt-updates-production',
                Records=batch
            )

            print(f"Sent {len(batch)} account update records to Kinesis")

    return {'statusCode': 200, 'body': f'Processed {len(records)} account updates'}

def extract_account_data(image):
    """
    Extract account data from DynamoDB item image
    Returns account object expected by KT Server
    """
    if not image:
        return None

    try:
        # Extract account data from DynamoDB binary format
        account_data = image.get('D', {}).get('B')
        if account_data:
            # Decode binary account data JSON
            account_json = json.loads(base64.b64decode(account_data).decode('utf-8'))
        else:
            account_json = {}

        # Extract UUID from binary format
        uuid_bytes = image.get('U', {}).get('B')
        if uuid_bytes:
            aci = base64.b64decode(uuid_bytes)
        else:
            return None

        # Extract other fields
        phone_number = image.get('P', {}).get('S', '')
        username_hash = image.get('N', {}).get('B')
        if username_hash:
            username_hash = base64.b64decode(username_hash)

        # Create account object in format expected by KT Server
        account = {
            'ACI': list(aci),  # Convert bytes to array for JSON serialization
            'Number': phone_number,
            'ACIIdentityKey': account_json.get('identityKey', []),
            'UsernameHash': list(username_hash) if username_hash else []
        }

        return account

    except Exception as e:
        print(f"Error extracting account data: {e}")
        return None

def get_partition_key(account):
    """
    Generate partition key based on account ACI for even distribution
    """
    if account and account.get('ACI'):
        aci_hash = hash(str(account['ACI'][:8]))  # Use first 8 bytes for hash
        return f"account-{aci_hash % 100:02d}"
    return "account-unknown"

