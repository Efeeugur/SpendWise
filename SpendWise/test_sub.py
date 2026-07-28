import re

filepath = '/Users/efeugur/Documents/Github/SpendWise/SpendWise/Views/SecurityView.swift'
with open(filepath, 'r', encoding='utf-8') as f:
    original_content = f.read()

lines = original_content.split('\n')
new_lines = []
modified = False

for line in lines:
    if '.localized' in line:
        new_lines.append(line)
        continue
        
    new_line = line
    
    # Text("...") -> Text("...".localized)
    new_line = re.sub(r'Text\(\s*"([^"]+)"\s*\)', r'Text("\1".localized)', new_line)
    
    if new_line != line:
        modified = True
        print(f"Modifying line: {line.strip()}")
        print(f"To: {new_line.strip()}")
    new_lines.append(new_line)

if modified:
    print("Modified successfully.")
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_lines))
else:
    print("No modifications made.")
