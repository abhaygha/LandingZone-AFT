#!/usr/bin/env python3

import json
import sys
import re
from typing import Dict, Any

def validate_email(email: str) -> bool:
    """Validate email format."""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))

def validate_ou_path(ou_path: str) -> bool:
    """Validate OU path format."""
    pattern = r'^[a-zA-Z0-9-_/]+$'
    return bool(re.match(pattern, ou_path))

def validate_account_name(account_name: str) -> bool:
    """Validate account name format."""
    pattern = r'^[a-zA-Z0-9-_]+$'
    return bool(re.match(pattern, account_name))

def validate_custom_fields(custom_fields: Dict[str, Any]) -> bool:
    """Validate custom fields."""
    required_fields = ['environment', 'cost_center', 'project']
    return all(field in custom_fields for field in required_fields)

def validate_account_request(request: Dict[str, Any]) -> bool:
    """Validate account request structure and content."""
    try:
        # Validate top-level structure
        if 'account_request' not in request:
            print("Error: Missing 'account_request' in request")
            return False

        account_request = request['account_request']

        # Validate control tower parameters
        if 'control_tower_parameters' not in account_request:
            print("Error: Missing 'control_tower_parameters' in account request")
            return False

        ct_params = account_request['control_tower_parameters']
        if not validate_email(ct_params.get('AccountEmail', '')):
            print("Error: Invalid AccountEmail format")
            return False

        if not validate_account_name(ct_params.get('AccountName', '')):
            print("Error: Invalid AccountName format")
            return False

        if not validate_ou_path(ct_params.get('ManagedOrganizationalUnit', '')):
            print("Error: Invalid ManagedOrganizationalUnit format")
            return False

        # Validate custom fields
        if 'custom_fields' not in account_request:
            print("Error: Missing 'custom_fields' in account request")
            return False

        if not validate_custom_fields(account_request['custom_fields']):
            print("Error: Missing required custom fields")
            return False

        # Validate account tags
        if 'account_tags' not in account_request:
            print("Error: Missing 'account_tags' in account request")
            return False

        required_tags = ['Environment', 'CostCenter', 'Project']
        account_tags = account_request['account_tags']
        if not all(tag in account_tags for tag in required_tags):
            print("Error: Missing required account tags")
            return False

        return True

    except Exception as e:
        print(f"Error during validation: {str(e)}")
        return False

def main():
    try:
        # Read account request from stdin
        request = json.load(sys.stdin)
        
        if validate_account_request(request):
            print("Account request is valid")
            sys.exit(0)
        else:
            print("Account request is invalid")
            sys.exit(1)

    except json.JSONDecodeError:
        print("Error: Invalid JSON format")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main() 