#!/usr/bin/env python3
import os
import re

# List of files that use DropdownButton2
files_to_fix = [
    "lib/screens/Become a servie man/choose_more_services_page.dart",
    "lib/screens/Become a servie man/choose_service_page.dart", 
    "lib/screens/Become a servie man/renew_service.dart",
    "lib/screens/Become a servie man/profile_service_man.dart",
    "lib/screens/serviceman/servicer.dart",
    "lib/screens/edit_profile_screen.dart",
    "lib/screens/serviceman settings profile/serviceman_profile_edit.dart",
    "lib/screens/Address page/address_add.dart",
    "lib/screens/Address page/address_update.dart"
]

def fix_dropdown_button2_file(filepath):
    """Fix DropdownButton2 API issues in a single file"""
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Remove icon parameter and its value (multiline)
    content = re.sub(
        r'icon:\s*const\s+Icon\(\s*[^)]+\),?\s*\n',
        '',
        content,
        flags=re.MULTILINE
    )
    
    # Remove icon parameter (single line)
    content = re.sub(
        r'icon:\s*[^,\n]+,?\s*\n',
        '',
        content,
        flags=re.MULTILINE
    )
    
    # Remove buttonHeight parameter
    content = re.sub(
        r'buttonHeight:\s*\d+,?\s*\n',
        '',
        content,
        flags=re.MULTILINE
    )
    
    # Remove searchInnerWidgetHeight parameter
    content = re.sub(
        r'searchInnerWidgetHeight:\s*\d+[^,\n]*,?\s*\n',
        '',
        content,
        flags=re.MULTILINE
    )

    # Remove itemHeight parameter
    content = re.sub(
        r'itemHeight:\s*\d+,?\s*\n',
        '',
        content,
        flags=re.MULTILINE
    )

    # Remove dropdownMaxHeight parameter
    content = re.sub(
        r'dropdownMaxHeight:\s*[^,\n]+,?\s*\n',
        '',
        content,
        flags=re.MULTILINE
    )

    # Remove buttonPadding parameter
    content = re.sub(
        r'buttonPadding:\s*[^,\n]+,?\s*\n',
        '',
        content,
        flags=re.MULTILINE
    )

    # Remove iconSize parameter
    content = re.sub(
        r'iconSize:\s*\d+,?\s*\n',
        '',
        content,
        flags=re.MULTILINE
    )
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed: {filepath}")
    else:
        print(f"No changes needed: {filepath}")

def main():
    print("Fixing DropdownButton2 API issues...")
    for filepath in files_to_fix:
        fix_dropdown_button2_file(filepath)
    print("Done!")

if __name__ == "__main__":
    main()
