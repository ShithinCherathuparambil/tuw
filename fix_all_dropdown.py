#!/usr/bin/env python3
import os
import re

# List of files that use DropdownButton2
files_to_fix = [
    "lib/screens/Become a servie man/choose_more_services_page.dart",
    "lib/screens/Become a servie man/renew_service.dart",
    "lib/screens/Become a servie man/profile_service_man.dart",
    "lib/screens/serviceman/servicer.dart",
    "lib/screens/edit_profile_screen.dart",
    "lib/screens/serviceman settings profile/serviceman_profile_edit.dart",
    "lib/screens/Address page/address_add.dart",
    "lib/screens/Address page/address_update.dart"
]

def fix_dropdown_file(filepath):
    """Fix DropdownButton2 issues in a single file"""
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Comment out the import statement
    content = re.sub(
        r"import 'package:dropdown_button2/dropdown_button2\.dart';",
        "// import 'package:dropdown_button2/dropdown_button2.dart';  // Replaced with standard DropdownButton",
        content
    )
    
    # Replace DropdownButton2 with DropdownButton
    content = content.replace('DropdownButton2<', 'DropdownButton<')
    content = content.replace('DropdownButton2(', 'DropdownButton(')
    
    # Remove lines with deprecated parameters
    lines = content.split('\n')
    new_lines = []
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Skip lines with deprecated parameters
        if any(param in line for param in [
            'icon: const Icon(',
            'buttonHeight:',
            'itemHeight:',
            'buttonPadding:',
            'itemPadding:',
            'searchInnerWidgetHeight:',
            'dropdownMaxHeight:',
            'iconSize:',
            'customButton:'
        ]):
            # For icon parameters, skip multiple lines until we find the closing
            if 'icon: const Icon(' in line:
                # Skip until we find the closing parenthesis and comma
                while i < len(lines) and not ('),' in lines[i]):
                    i += 1
                i += 1  # Skip the line with ),
                continue
            elif 'customButton:' in line:
                # Skip until we find the next parameter or closing
                while i < len(lines) and not any(x in lines[i] for x in ['onChanged:', 'value:', 'items:', '},', '),']):
                    i += 1
                continue
            else:
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
    else:
        print(f"No changes needed: {filepath}")

def main():
    print("Fixing all DropdownButton2 files...")
    for filepath in files_to_fix:
        fix_dropdown_file(filepath)
    print("Done!")

if __name__ == "__main__":
    main()
