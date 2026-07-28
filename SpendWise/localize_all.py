import os
import re

directories = [
    '/Users/efeugur/Documents/Github/SpendWise/SpendWise/Views',
    '/Users/efeugur/Documents/Github/SpendWise/SpendWise/Managers',
    '/Users/efeugur/Documents/Github/SpendWise/SpendWise/Models'
]

strings_to_localize = set()

def localize_file(filepath):
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
        
        # .navigationTitle("...") -> .navigationTitle("...".localized)
        new_line = re.sub(r'\.navigationTitle\(\s*"([^"]+)"\s*\)', r'.navigationTitle("\1".localized)', new_line)
        
        # Button("..." -> Button("...".localized
        new_line = re.sub(r'Button\(\s*"([^"]+)"\s*([,\)])', r'Button("\1".localized\2', new_line)
        
        # Label("..." -> Label("...".localized
        new_line = re.sub(r'Label\(\s*"([^"]+)"\s*,', r'Label("\1".localized,', new_line)
        
        # Picker("..." -> Picker("...".localized
        new_line = re.sub(r'Picker\(\s*"([^"]+)"\s*,', r'Picker("\1".localized,', new_line)
        
        # Section(header: Text("...")) is handled by Text
        
        # prompt: "..." -> prompt: "...".localized
        new_line = re.sub(r'prompt:\s*"([^"]+)"', r'prompt: "\1".localized', new_line)

        # "Guest User"
        new_line = new_line.replace('return "Guest User"', 'return "Guest User".localized')

        # specific strings
        new_line = new_line.replace('Text("\(incomes.count) income\(incomes.count == 1 ? "" : "s")")', 'Text(String(format: "%d incomes".localized, incomes.count))')
        new_line = new_line.replace('Text("\(expenses.count) expense\(expenses.count == 1 ? "" : "s")")', 'Text(String(format: "%d expenses".localized, expenses.count))')
        new_line = new_line.replace('Text(UserDefaultsManager.loadSecurityType().rawValue)', 'Text(UserDefaultsManager.loadSecurityType().rawValue.localized)')
        new_line = new_line.replace('Text("Start tracking your income sources to get insights into your financial growth.")', 'Text("Start tracking your income sources to get insights into your financial growth.".localized)')
        new_line = new_line.replace('Text("Start tracking your expenses to understand your spending patterns and manage your budget.")', 'Text("Start tracking your expenses to understand your spending patterns and manage your budget.".localized)')
        new_line = new_line.replace('Text("Add First Income")', 'Text("Add First Income".localized)')
        new_line = new_line.replace('Text("Add First Expense")', 'Text("Add First Expense".localized)')

        if new_line != line:
            modified = True
        new_lines.append(new_line)

    content = '\n'.join(new_lines)

    # Collect .localized strings
    for m in re.finditer(r'"([^"]+)"\.localized', content):
        if not m.group(1).startswith('%') and m.group(1).strip():
            strings_to_localize.add(m.group(1))

    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

processed_count = 0
for d in directories:
    for root, _, files in os.walk(d):
        for file in files:
            if file.endswith('.swift'):
                if localize_file(os.path.join(root, file)):
                    processed_count += 1

strings_to_localize.add("No Protection")
strings_to_localize.add("Guest User")
strings_to_localize.add("%d incomes")
strings_to_localize.add("%d expenses")

with open('/Users/efeugur/Documents/Github/SpendWise/SpendWise/localized_keys.txt', 'w', encoding='utf-8') as f:
    for s in sorted(list(strings_to_localize)):
        f.write(s + '\n')

print(f"Modified {processed_count} files. Found {len(strings_to_localize)} keys to localize.")
