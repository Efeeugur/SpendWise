import os

en_file = '/Users/efeugur/Documents/Github/SpendWise/SpendWise/Localization/en.lproj/Localizable.strings'
tr_file = '/Users/efeugur/Documents/Github/SpendWise/SpendWise/Localization/tr.lproj/Localizable.strings'

en_strings = """
"Profile & Settings" = "Profile & Settings";
"Guest User" = "Guest User";
"No Protection" = "No Protection";
"%d incomes" = "%d incomes";
"Start tracking your income sources to get insights into your financial growth." = "Start tracking your income sources to get insights into your financial growth.";
"Add First Income" = "Add First Income";
"%d expenses" = "%d expenses";
"Start tracking your expenses to understand your spending patterns and manage your budget." = "Start tracking your expenses to understand your spending patterns and manage your budget.";
"Add First Expense" = "Add First Expense";
"""

tr_strings = """
"Profile & Settings" = "Profil ve Ayarlar";
"Guest User" = "Misafir Kullanıcı";
"No Protection" = "Koruma Yok";
"%d incomes" = "%d gelir";
"Start tracking your income sources to get insights into your financial growth." = "Finansal büyümeniz hakkında bilgi edinmek için gelir kaynaklarınızı takip etmeye başlayın.";
"Add First Income" = "İlk Geliri Ekle";
"%d expenses" = "%d gider";
"Start tracking your expenses to understand your spending patterns and manage your budget." = "Harcama alışkanlıklarınızı anlamak ve bütçenizi yönetmek için giderlerinizi takip etmeye başlayın.";
"Add First Expense" = "İlk Gideri Ekle";
"""

def append_to_file(filepath, new_strings):
    with open(filepath, 'a', encoding='utf-8') as f:
        f.write('\n' + new_strings.strip() + '\n')

append_to_file(en_file, en_strings)
append_to_file(tr_file, tr_strings)

print("Done appending localization strings.")
