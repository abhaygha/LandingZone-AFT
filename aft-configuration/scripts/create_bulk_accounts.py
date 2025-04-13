#!/usr/bin/env python3

import json
import boto3
import time
from typing import Dict, List, Any
from concurrent.futures import ThreadPoolExecutor
from botocore.exceptions import ClientError

class BulkAccountCreator:
    def __init__(self, batch_size: int = 10):
        self.organizations = boto3.client('organizations')
        self.controltower = boto3.client('controltower')
        self.sns = boto3.client('sns')
        self.batch_size = batch_size
        self.topic_arn = "arn:aws:sns:region:account-id:aft-pipeline-notifications"  # Replace with your SNS topic ARN

    def create_account(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Create a single AWS account."""
        result = {
            'request': request,
            'status': 'pending',
            'account_id': None,
            'error': None
        }

        try:
            # Extract parameters
            ct_params = request['account_request']['control_tower_parameters']
            
            # Create account
            response = self.organizations.create_account(
                Email=ct_params['AccountEmail'],
                AccountName=ct_params['AccountName'],
                RoleName='OrganizationAccountAccessRole',
                IamUserAccessToBilling='ALLOW'
            )

            # Wait for account creation
            create_status = response['CreateAccountStatus']
            while create_status['State'] == 'IN_PROGRESS':
                time.sleep(5)
                create_status = self.organizations.describe_create_account_status(
                    CreateAccountRequestId=create_status['Id']
                )

            if create_status['State'] == 'SUCCEEDED':
                result['status'] = 'success'
                result['account_id'] = create_status['AccountId']
                
                # Apply Control Tower guardrails
                self.controltower.enable_control(
                    ControlIdentifier='AWS-GR_AUTOSCALING_LAUNCH_CONFIG_PUBLIC_IP_DISABLED',
                    TargetIdentifier=result['account_id']
                )
                
                # Apply account tags
                self.organizations.tag_resource(
                    ResourceId=result['account_id'],
                    Tags=[{'Key': k, 'Value': v} for k, v in request['account_request']['account_tags'].items()]
                )
            else:
                result['status'] = 'failed'
                result['error'] = create_status.get('FailureReason', 'Unknown error')

        except ClientError as e:
            result['status'] = 'failed'
            result['error'] = str(e)

        return result

    def process_batch(self, requests: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Process a batch of account creation requests."""
        results = []
        
        with ThreadPoolExecutor(max_workers=self.batch_size) as executor:
            results = list(executor.map(self.create_account, requests))
            
        # Send notification
        success_count = sum(1 for r in results if r['status'] == 'success')
        self.sns.publish(
            TopicArn=self.topic_arn,
            Message=json.dumps({
                'batch_results': results,
                'summary': {
                    'total': len(results),
                    'success': success_count,
                    'failed': len(results) - success_count
                }
            }),
            Subject=f'Batch Account Creation Results: {success_count}/{len(results)} Success'
        )
        
        return results

    def create_accounts(self, requests: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Create accounts in batches."""
        total_results = {
            'total_requests': len(requests),
            'successful_creations': 0,
            'failed_creations': 0,
            'results': []
        }

        # Process in batches
        for i in range(0, len(requests), self.batch_size):
            batch = requests[i:i + self.batch_size]
            batch_results = self.process_batch(batch)
            
            total_results['results'].extend(batch_results)
            total_results['successful_creations'] += sum(1 for r in batch_results if r['status'] == 'success')
            total_results['failed_creations'] += sum(1 for r in batch_results if r['status'] == 'failed')
            
            # Wait between batches to avoid rate limits
            time.sleep(30)

        return total_results

def main():
    try:
        # Read bulk account requests from stdin
        data = json.load(sys.stdin)
        
        if 'bulk_account_requests' not in data:
            print("Error: Missing 'bulk_account_requests' in input")
            sys.exit(1)

        creator = BulkAccountCreator()
        results = creator.create_accounts(data['bulk_account_requests'])
        
        # Print results
        print(json.dumps(results, indent=2))
        
        # Exit with error if any creations failed
        if results['failed_creations'] > 0:
            sys.exit(1)
        else:
            sys.exit(0)

    except json.JSONDecodeError:
        print("Error: Invalid JSON format")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main() 