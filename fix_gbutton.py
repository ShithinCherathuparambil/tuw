#!/usr/bin/env python3
import os
import re

# List of files that use GButton
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

def fix_gbutton_file(filepath):
    """Fix GButton API issues in a single file"""
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Find GButton widgets that don't have icon parameter and add it
    # Pattern to match GButton( without icon parameter
    gbutton_pattern = r'GButton\(\s*(?!.*icon:)'
    
    # Replace with GButton that includes icon parameter
    def add_icon_to_gbutton(match):
        return 'GButton(\n                  icon: Icons.home,'
    
    content = re.sub(gbutton_pattern, add_icon_to_gbutton, content)
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed: {filepath}")
    else:
        print(f"No changes needed: {filepath}")

def main():
    print("Fixing GButton API issues...")
    for filepath in files_to_fix:
        fix_gbutton_file(filepath)
    print("Done!")

if __name__ == "__main__":
    main()
