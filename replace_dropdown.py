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

def replace_dropdown_button2(filepath):
    """Replace DropdownButton2 with standard DropdownButton"""
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Replace DropdownButton2 with DropdownButton
    content = content.replace('DropdownButton2(', 'DropdownButton(')
    content = content.replace('DropdownButton2<', 'DropdownButton<')
    
    # Remove deprecated parameters by removing entire lines
    lines = content.split('\n')
    new_lines = []
    
    skip_next_lines = 0
    for i, line in enumerate(lines):
        if skip_next_lines > 0:
            skip_next_lines -= 1
            continue
            
        # Skip lines with deprecated parameters
        if any(param in line for param in [
            'icon: const Icon(',
            'buttonHeight:',
            'itemHeight:',
            'buttonPadding:',
            'itemPadding:',
            'searchInnerWidgetHeight:',
            'dropdownMaxHeight:',
            'iconSize:'
        ]):
            # For icon parameters, skip multiple lines until we find the closing
            if 'icon: const Icon(' in line:
                # Skip until we find the closing parenthesis and comma
                skip_count = 0
                for j in range(i, min(i + 10, len(lines))):
                    skip_count += 1
                    if '),' in lines[j] or '),' in lines[j]:
                        break
                skip_next_lines = skip_count - 1
            continue
        else:
            new_lines.append(line)
    
    content = '\n'.join(new_lines)
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed: {filepath}")
    else:
        print(f"No changes needed: {filepath}")

def main():
    print("Replacing DropdownButton2 with DropdownButton...")
    for filepath in files_to_fix:
        replace_dropdown_button2(filepath)
    print("Done!")

if __name__ == "__main__":
    main()
