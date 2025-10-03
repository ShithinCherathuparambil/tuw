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
    """Fix DropdownButton2 API issues in a single file by removing deprecated parameters"""
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return
    
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    original_lines = lines[:]
    new_lines = []
    
    for line in lines:
        # Skip lines that contain deprecated parameters
        if any(param in line for param in [
            'icon: const Icon(',
            'icon:',
            'buttonHeight:',
            'itemHeight:',
            'buttonPadding:',
            'itemPadding:',
            'searchInnerWidgetHeight:',
            'dropdownMaxHeight:',
            'iconSize:'
        ]):
            # Skip this line and any continuation lines for Icon widgets
            if 'icon: const Icon(' in line:
                # Skip until we find the closing parenthesis and comma
                continue
            else:
                continue
        else:
            new_lines.append(line)
    
    if new_lines != original_lines:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
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
