import os
import re

en_file = '/Users/efeugur/Documents/Github/SpendWise/SpendWise/Localization/en.lproj/Localizable.strings'
tr_file = '/Users/efeugur/Documents/Github/SpendWise/SpendWise/Localization/tr.lproj/Localizable.strings'
keys_file = '/Users/efeugur/Documents/Github/SpendWise/SpendWise/localized_keys.txt'

with open(keys_file, 'r', encoding='utf-8') as f:
    keys = [line.strip() for line in f.read().split('\n') if line.strip()]

tr_dict = {
    "%d expenses": "%d gider",
    "%d incomes": "%d gelir",
    "Account": "Hesap",
    "Account Locked": "Hesap Kilitlendi",
    "Add Expense": "Gider Ekle",
    "Add First Expense": "İlk Gideri Ekle",
    "Add First Income": "İlk Geliri Ekle",
    "Add Income": "Gelir Ekle",
    "Add Photo": "Fotoğraf Ekle",
    "Add Reminder": "Hatırlatıcı Ekle",
    "Add optional note...": "İsteğe bağlı not ekle...",
    "Already have an account?": "Zaten bir hesabınız var mı?",
    "Amount": "Tutar",
    "App Info": "Uygulama Bilgisi",
    "App Protection": "Uygulama Koruması",
    "Application": "Uygulama",
    "Are you sure you want to delete this expense entry?": "Bu gider kaydını silmek istediğinize emin misiniz?",
    "Are you sure you want to delete this income entry?": "Bu gelir kaydını silmek istediğinize emin misiniz?",
    "Are you sure you want to permanently delete your account? This action cannot be undone.": "Hesabınızı kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.",
    "Are you sure you want to sign out?": "Çıkış yapmak istediğinize emin misiniz?",
    "At least 4 characters": "En az 4 karakter",
    "BIOMETRIC AUTHENTICATION": "BİYOMETRİK DOĞRULAMA",
    "Biometric authentication is not available on this device.": "Bu cihazda biyometrik doğrulama kullanılamıyor.",
    "Budget Optimization": "Bütçe Optimizasyonu",
    "Cancel": "İptal",
    "Category": "Kategori",
    "Caution": "Dikkat",
    "Change": "Değiştir",
    "Close": "Kapat",
    "Confirm Password": "Şifreyi Onayla",
    "Continue as Guest": "Misafir Olarak Devam Et",
    "Continue with Google": "Google ile Devam Et",
    "Create Account": "Hesap Oluştur",
    "Create a secure password to protect your financial data": "Finansal verilerinizi korumak için güvenli bir şifre oluşturun",
    "Currency": "Para Birimi",
    "Danger": "Tehlike",
    "Date": "Tarih",
    "Delete": "Sil",
    "Delete Account": "Hesabı Sil",
    "Developer": "Geliştirici",
    "Don't have an account?": "Hesabınız yok mu?",
    "Done": "Bitti",
    "Edit": "Düzenle",
    "Edit Expense": "Gideri Düzenle",
    "Edit Income": "Geliri Düzenle",
    "Email": "E-posta",
    "Enter email": "E-posta girin",
    "Enter expense name": "Gider adı girin",
    "Enter income name": "Gelir adı girin",
    "Enter username": "Kullanıcı adı girin",
    "Excellent": "Mükemmel",
    "Expense Categories": "Gider Kategorileri",
    "Expense Limit Exceeded!": "Gider Limiti Aşıldı!",
    "Expense Name": "Gider Adı",
    "Expense Reminder": "Gider Hatırlatıcısı",
    "Expenses": "Giderler",
    "Export Data": "Verileri Dışa Aktar",
    "Food Savings": "Yemek Tasarrufu",
    "Guest User": "Misafir Kullanıcı",
    "Help & FAQ": "Yardım & SSS",
    "Income Categories": "Gelir Kategorileri",
    "Income Name": "Gelir Adı",
    "Income vs Expenses": "Gelir ve Giderler",
    "Incomes": "Gelirler",
    "Language": "Dil",
    "Limit saved!": "Limit kaydedildi!",
    "Member Since": "Üyelik Tarihi",
    "Monthly Spending Limit": "Aylık Harcama Limiti",
    "Monthly Trend": "Aylık Trend",
    "Net Balance": "Net Bakiye",
    "No Expenses Yet": "Henüz Gider Yok",
    "No Income Yet": "Henüz Gelir Yok",
    "No Protection": "Koruma Yok",
    "No Security - Continue": "Güvenlik Yok - Devam Et",
    "No data available": "Veri yok",
    "No recent transactions": "Son işlem yok",
    "Note": "Not",
    "Notifications": "Bildirimler",
    "OK": "Tamam",
    "OR": "VEYA",
    "PASSWORD SETTINGS": "ŞİFRE AYARLARI",
    "Password": "Şifre",
    "Passwords match": "Şifreler eşleşiyor",
    "Photo": "Fotoğraf",
    "Profile": "Profil",
    "Profile & Settings": "Profil ve Ayarlar",
    "Protect your financial data with advanced security options": "Gelişmiş güvenlik seçenekleriyle finansal verilerinizi koruyun",
    "Rate App": "Uygulamayı Değerlendir",
    "Recent Transactions": "Son İşlemler",
    "Refresh": "Yenile",
    "Reminder": "Hatırlatıcı",
    "Reminder Date": "Hatırlatma Tarihi",
    "Remove": "Kaldır",
    "Remove Photo": "Fotoğrafı Kaldır",
    "Reports": "Raporlar",
    "Requirements:": "Gereksinimler:",
    "SECURITY TEST": "GÜVENLİK TESTİ",
    "SECURITY TYPE": "GÜVENLİK TÜRÜ",
    "Save": "Kaydet",
    "Save Password": "Şifreyi Kaydet",
    "Saving Tip": "Tasarruf İpucu",
    "Search Expenses": "Gider Ara",
    "Search Income": "Gelir Ara",
    "Security": "Güvenlik",
    "Set Limit": "Limit Belirle",
    "Set Password": "Şifre Belirle",
    "Settings": "Ayarlar",
    "Sign In": "Giriş Yap",
    "Sign In or Create Account": "Giriş Yap veya Hesap Oluştur",
    "Sign Out": "Çıkış Yap",
    "Sign Out Confirmation": "Çıkış Onayı",
    "Sign in to your account": "Hesabınıza giriş yapın",
    "Sign in with Password": "Şifre ile Giriş Yap",
    "Smart Recommendations": "Akıllı Öneriler",
    "Spending Analysis": "Harcama Analizi",
    "Spending Decrease": "Harcama Düşüşü",
    "Spending Increase": "Harcama Artışı",
    "Spending Limit Alert!": "Harcama Limiti Uyarısı!",
    "Spending Ratio": "Harcama Oranı",
    "Start tracking your expenses to understand your spending patterns and manage your budget.": "Harcama alışkanlıklarınızı anlamak ve bütçenizi yönetmek için giderlerinizi takip etmeye başlayın.",
    "Start tracking your income sources to get insights into your financial growth.": "Finansal büyümeniz hakkında bilgi edinmek için gelir kaynaklarınızı takip etmeye başlayın.",
    "Summary": "Özet",
    "Support": "Destek",
    "Theme": "Tema",
    "Total Expenses": "Toplam Gider",
    "Total Income": "Toplam Gelir",
    "Track your income sources": "Gelir kaynaklarınızı takip edin",
    "Track your spending": "Harcamalarınızı takip edin",
    "Type": "Tür",
    "Update your expense details": "Gider detaylarınızı güncelleyin",
    "Update your income details": "Gelir detaylarınızı güncelleyin",
    "User": "Kullanıcı",
    "Username": "Kullanıcı Adı",
    "Version": "Sürüm",
    "Welcome Back": "Tekrar Hoş Geldiniz",
    "You are doing great!": "Harika gidiyorsun!",
    "🔒 Your data is secure": "🔒 Verileriniz güvende"
}

def get_existing_keys(filepath):
    existing = set()
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            for line in f:
                # Match "key" = "value";
                m = re.match(r'^\s*"([^"]+)"\s*=', line)
                if m:
                    existing.add(m.group(1))
    except Exception as e:
        print(f"Error parsing {filepath}: {e}")
    return existing

en_existing = get_existing_keys(en_file)
tr_existing = get_existing_keys(tr_file)

en_to_add = []
tr_to_add = []

for key in keys:
    # Handle interpolation literals found in strings
    sanitized_key = key.replace('\\(', '(').replace('\\)', ')') # basic sanitization if needed
    if sanitized_key not in en_existing:
        en_to_add.append(f'"{sanitized_key}" = "{sanitized_key}";\n')
    
    if sanitized_key not in tr_existing:
        tr_val = tr_dict.get(sanitized_key, sanitized_key)
        tr_to_add.append(f'"{sanitized_key}" = "{tr_val}";\n')

if en_to_add:
    with open(en_file, 'a', encoding='utf-8') as f:
        f.write('\n// Auto-added Keys\n')
        f.writelines(en_to_add)

if tr_to_add:
    with open(tr_file, 'a', encoding='utf-8') as f:
        f.write('\n// Auto-added Keys\n')
        f.writelines(tr_to_add)

print(f"Added {len(en_to_add)} keys to English.")
print(f"Added {len(tr_to_add)} keys to Turkish.")
