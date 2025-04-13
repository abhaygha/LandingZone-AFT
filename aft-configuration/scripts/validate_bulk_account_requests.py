#!/usr/bin/env python3

import json
import sys
import re
from typing import Dict, Any, List
from concurrent.futures import ThreadPoolExecutor
import boto3
from botocore.exceptions import ClientError

class BulkAccountValidator:
    def __init__(self):
        self.organizations = boto3.client('organizations')
        self.ses = boto3.client('ses')
        self.valid_ous = self._get_valid_ous()
        self.existing_accounts = self._get_existing_accounts()

    def _get_valid_ous(self) -> List[str]:
        """Get list of valid OUs from AWS Organizations."""
        try:
            ous = []
            paginator = self.organizations.get_paginator('list_organizational_units_for_parent')
            for page in paginator.paginate(ParentId='r-xxxx'):  # Replace with your root ID
                ous.extend([ou['Id'] for ou in page['OrganizationalUnits']])
            return ous
        except ClientError as e:
            print(f"Error getting OUs: {str(e)}")
            return []

    def _get_existing_accounts(self) -> List[str]:
        """Get list of existing account emails."""
        try:
            accounts = []
            paginator = self.organizations.get_paginator('list_accounts')
            for page in paginator.paginate():
                accounts.extend([acc['Email'] for acc in page['Accounts']])
            return accounts
        except ClientError as e:
            print(f"Error getting accounts: {str(e)}")
            return []

    def validate_email(self, email: str) -> bool:
        """Validate email format and check for duplicates."""
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not bool(re.match(pattern, email)):
            return False
        return email not in self.existing_accounts

    def validate_ou(self, ou_id: str) -> bool:
        """Validate OU exists."""
        return ou_id in self.valid_ous

    def validate_account_name(self, account_name: str) -> bool:
        """Validate account name format."""
        pattern = r'^[a-zA-Z0-9-_]+$'
        return bool(re.match(pattern, account_name))

    def validate_custom_fields(self, custom_fields: Dict[str, Any]) -> bool:
        """Validate custom fields."""
        required_fields = ['environment', 'cost_center', 'project']
        return all(field in custom_fields for field in required_fields)

    def validate_account_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Validate a single account request."""
        validation_result = {
            'valid': True,
            'errors': []
        }

        try:
            account_request = request['account_request']
            ct_params = account_request['control_tower_parameters']

            # Validate email
            if not self.validate_email(ct_params.get('AccountEmail', '')):
                validation_result['valid'] = False
                validation_result['errors'].append('Invalid or duplicate AccountEmail')

            # Validate account name
            if not self.validate_account_name(ct_params.get('AccountName', '')):
                validation_result['valid'] = False
                validation_result['errors'].append('Invalid AccountName format')

            # Validate OU
            if not self.validate_ou(ct_params.get('ManagedOrganizationalUnit', '')):
                validation_result['valid'] = False
                validation_result['errors'].append('Invalid ManagedOrganizationalUnit')

            # Validate custom fields
            if not self.validate_custom_fields(account_request.get('custom_fields', {})):
                validation_result['valid'] = False
                validation_result['errors'].append('Missing required custom fields')

            # Validate account tags
            required_tags = ['Environment', 'CostCenter', 'Project']
            account_tags = account_request.get('account_tags', {})
            if not all(tag in account_tags for tag in required_tags):
                validation_result['valid'] = False
                validation_result['errors'].append('Missing required account tags')

        except Exception as e:
            validation_result['valid'] = False
            validation_result['errors'].append(f'Error during validation: {str(e)}')

        return validation_result

    def validate_bulk_requests(self, requests: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Validate multiple account requests in parallel."""
        results = {
            'total_requests': len(requests),
            'valid_requests': 0,
            'invalid_requests': 0,
            'validation_results': []
        }

        with ThreadPoolExecutor(max_workers=10) as executor:
            validation_results = list(executor.map(self.validate_account_request, requests))

        for result in validation_results:
            if result['valid']:
                results['valid_requests'] += 1
            else:
                results['invalid_requests'] += 1
            results['validation_results'].append(result)

        return results

def main():
    try:
        # Read bulk account requests from stdin
        data = json.load(sys.stdin)
        
        if 'bulk_account_requests' not in data:
            print("Error: Missing 'bulk_account_requests' in input")
            sys.exit(1)

        validator = BulkAccountValidator()
        results = validator.validate_bulk_requests(data['bulk_account_requests'])
        
        # Print validation results
        print(json.dumps(results, indent=2))
        
        # Exit with error if any requests are invalid
        if results['invalid_requests'] > 0:
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