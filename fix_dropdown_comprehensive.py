#!/usr/bin/env python3
import os
import re

# List of files that use DropdownButton2
files_to_fix = [
    "lib/screens/Address page/address_add.dart",
    "lib/screens/Address page/address_update.dart", 
    "lib/screens/edit_profile_screen.dart",
    "lib/screens/Become a servie man/profile_service_man.dart",
    "lib/screens/Become a servie man/renew_service.dart",
    "lib/screens/serviceman settings profile/serviceman_profile_edit.dart",
    "lib/screens/Become a servie man/choose_service_page.dart",
    "lib/screens/Become a servie man/choose_more_services_page.dart",
    "lib/screens/serviceman/servicer.dart"
]

# Deprecated parameters that need to be removed
deprecated_params = [
    'icon:',
    'buttonHeight:',
    'itemHeight:',
    'buttonPadding:',
    'itemPadding:',
    'searchInnerWidgetHeight:',
    'dropdownMaxHeight:',
    'iconSize:',
    'customButton:'
]

def fix_dropdown_file(filepath):
    """Fix DropdownButton2 issues in a single file"""
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Split into lines for easier processing
    lines = content.split('\n')
    new_lines = []
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Check if this line contains any deprecated parameter
        should_skip = False
        for param in deprecated_params:
            if param in line:
                should_skip = True
                break
        
        if should_skip:
            # Special handling for icon parameter which spans multiple lines
            if 'icon:' in line:
                # Skip lines until we find the closing parenthesis and comma
                while i < len(lines):
                    if '),' in lines[i]:
                        i += 1  # Skip the line with ),
                        break
                    i += 1
                continue
            elif 'customButton:' in line:
                # Skip lines until we find the next parameter or closing
                while i < len(lines):
                    next_line = lines[i] if i < len(lines) else ""
                    if any(x in next_line for x in ['onChanged:', 'value:', 'items:', 'hint:', 'isExpanded:', '},', '),']):
                        break
                    i += 1
                continue
            else:
                # For other single-line parameters, just skip this line
                i += 1
                continue
        else:
            new_lines.append(line)
            i += 1
    
    content = '\n'.join(new_lines)
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed: {filepath}")
        return True
    else:
        print(f"No changes needed: {filepath}")
        return False

def main():
    print("Fixing all DropdownButton2 deprecated parameter issues...")
    fixed_count = 0
    for filepath in files_to_fix:
        if fix_dropdown_file(filepath):
            fixed_count += 1
    print(f"Done! Fixed {fixed_count} files.")

if __name__ == "__main__":
    main()
