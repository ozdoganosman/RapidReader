import urllib.request
import json
import os

# Nuzul (revelation) order - maps nuzul order to mushaf surah number
NUZUL_ORDER = [
    96, 68, 73, 74, 1, 111, 81, 87, 92, 89,  # 1-10 (already done)
    93, 94, 103, 100, 108, 102, 107, 109, 105, 113,  # 11-20
    114, 112, 53, 80, 97, 91, 85, 95, 106, 101,  # 21-30
    75, 104, 77, 50, 90, 86, 54, 38, 7, 72,  # 31-40
    36, 25, 35, 19, 20, 56, 26, 27, 28, 17,  # 41-50
    10, 11, 12, 15, 6, 37, 31, 34, 39, 40,  # 51-60
    41, 42, 43, 44, 45, 46, 51, 88, 18, 16,  # 61-70
    71, 14, 21, 23, 32, 52, 67, 69, 70, 78,  # 71-80
    79, 82, 84, 30, 29, 83, 2, 8, 3, 33,  # 81-90
    60, 4, 99, 57, 47, 13, 55, 76, 65, 98,  # 91-100
    59, 24, 22, 63, 58, 49, 66, 64, 61, 62,  # 101-110
    48, 5, 9, 110  # 111-114
]

# Turkish surah names with Arabic
SURAH_NAMES = {
    1: "Fatiha Suresi (الفاتحة)",
    2: "Bakara Suresi (البقرة)",
    3: "Al-i İmran Suresi (آل عمران)",
    4: "Nisa Suresi (النساء)",
    5: "Maide Suresi (المائدة)",
    6: "En'am Suresi (الأنعام)",
    7: "A'raf Suresi (الأعراف)",
    8: "Enfal Suresi (الأنفال)",
    9: "Tevbe Suresi (التوبة)",
    10: "Yunus Suresi (يونس)",
    11: "Hud Suresi (هود)",
    12: "Yusuf Suresi (يوسف)",
    13: "Ra'd Suresi (الرعد)",
    14: "İbrahim Suresi (إبراهيم)",
    15: "Hicr Suresi (الحجر)",
    16: "Nahl Suresi (النحل)",
    17: "İsra Suresi (الإسراء)",
    18: "Kehf Suresi (الكهف)",
    19: "Meryem Suresi (مريم)",
    20: "Taha Suresi (طه)",
    21: "Enbiya Suresi (الأنبياء)",
    22: "Hac Suresi (الحج)",
    23: "Mü'minun Suresi (المؤمنون)",
    24: "Nur Suresi (النور)",
    25: "Furkan Suresi (الفرقان)",
    26: "Şuara Suresi (الشعراء)",
    27: "Neml Suresi (النمل)",
    28: "Kasas Suresi (القصص)",
    29: "Ankebut Suresi (العنكبوت)",
    30: "Rum Suresi (الروم)",
    31: "Lokman Suresi (لقمان)",
    32: "Secde Suresi (السجدة)",
    33: "Ahzab Suresi (الأحزاب)",
    34: "Sebe Suresi (سبأ)",
    35: "Fatır Suresi (فاطر)",
    36: "Yasin Suresi (يس)",
    37: "Saffat Suresi (الصافات)",
    38: "Sad Suresi (ص)",
    39: "Zümer Suresi (الزمر)",
    40: "Mü'min Suresi (غافر)",
    41: "Fussilet Suresi (فصلت)",
    42: "Şura Suresi (الشورى)",
    43: "Zuhruf Suresi (الزخرف)",
    44: "Duhan Suresi (الدخان)",
    45: "Casiye Suresi (الجاثية)",
    46: "Ahkaf Suresi (الأحقاف)",
    47: "Muhammed Suresi (محمد)",
    48: "Fetih Suresi (الفتح)",
    49: "Hucurat Suresi (الحجرات)",
    50: "Kaf Suresi (ق)",
    51: "Zariyat Suresi (الذاريات)",
    52: "Tur Suresi (الطور)",
    53: "Necm Suresi (النجم)",
    54: "Kamer Suresi (القمر)",
    55: "Rahman Suresi (الرحمن)",
    56: "Vakıa Suresi (الواقعة)",
    57: "Hadid Suresi (الحديد)",
    58: "Mücadele Suresi (المجادلة)",
    59: "Haşr Suresi (الحشر)",
    60: "Mümtehine Suresi (الممتحنة)",
    61: "Saff Suresi (الصف)",
    62: "Cuma Suresi (الجمعة)",
    63: "Münafikun Suresi (المنافقون)",
    64: "Teğabün Suresi (التغابن)",
    65: "Talak Suresi (الطلاق)",
    66: "Tahrim Suresi (التحريم)",
    67: "Mülk Suresi (الملك)",
    68: "Kalem Suresi (القلم)",
    69: "Hakka Suresi (الحاقة)",
    70: "Mearic Suresi (المعارج)",
    71: "Nuh Suresi (نوح)",
    72: "Cin Suresi (الجن)",
    73: "Müzzemmil Suresi (المزمل)",
    74: "Müddessir Suresi (المدثر)",
    75: "Kıyame Suresi (القيامة)",
    76: "İnsan Suresi (الإنسان)",
    77: "Mürselat Suresi (المرسلات)",
    78: "Nebe Suresi (النبأ)",
    79: "Naziat Suresi (النازعات)",
    80: "Abese Suresi (عبس)",
    81: "Tekvir Suresi (التكوير)",
    82: "İnfitar Suresi (الانفطار)",
    83: "Mutaffifin Suresi (المطففين)",
    84: "İnşikak Suresi (الانشقاق)",
    85: "Buruc Suresi (البروج)",
    86: "Tarık Suresi (الطارق)",
    87: "A'la Suresi (الأعلى)",
    88: "Gaşiye Suresi (الغاشية)",
    89: "Fecr Suresi (الفجر)",
    90: "Beled Suresi (البلد)",
    91: "Şems Suresi (الشمس)",
    92: "Leyl Suresi (الليل)",
    93: "Duha Suresi (الضحى)",
    94: "İnşirah Suresi (الشرح)",
    95: "Tin Suresi (التين)",
    96: "Alak Suresi (العلق)",
    97: "Kadr Suresi (القدر)",
    98: "Beyyine Suresi (البينة)",
    99: "Zilzal Suresi (الزلزلة)",
    100: "Adiyat Suresi (العاديات)",
    101: "Karia Suresi (القارعة)",
    102: "Tekasür Suresi (التكاثر)",
    103: "Asr Suresi (العصر)",
    104: "Hümeze Suresi (الهمزة)",
    105: "Fil Suresi (الفيل)",
    106: "Kureyş Suresi (قريش)",
    107: "Maun Suresi (الماعون)",
    108: "Kevser Suresi (الكوثر)",
    109: "Kafirun Suresi (الكافرون)",
    110: "Nasr Suresi (النصر)",
    111: "Tebbet Suresi (المسد)",
    112: "İhlas Suresi (الإخلاص)",
    113: "Felak Suresi (الفلق)",
    114: "Nas Suresi (الناس)"
}

def fetch_surah(surah_number):
    """Fetch surah from Acik Kuran API"""
    url = f"https://api.acikkuran.com/surah/{surah_number}"
    try:
        with urllib.request.urlopen(url, timeout=30) as response:
            data = json.loads(response.read().decode('utf-8'))
            return data
    except Exception as e:
        print(f"Error fetching surah {surah_number}: {e}")
        return None

def create_surah_file(nuzul_order, mushaf_number, output_dir):
    """Create text file for a surah"""
    print(f"Fetching surah {nuzul_order}/{len(NUZUL_ORDER)}: Mushaf #{mushaf_number}...")

    data = fetch_surah(mushaf_number)
    if not data or 'data' not in data:
        print(f"  Failed to fetch surah {mushaf_number}")
        return False

    surah_data = data['data']
    verses = surah_data.get('verses', [])

    # Get Turkish name
    surah_name = SURAH_NAMES.get(mushaf_number, f"Sure {mushaf_number}")

    # Build content
    lines = [surah_name, "Kuran-ı Kerim", ""]

    for verse in verses:
        translation = verse.get('translation', {})
        text = translation.get('text', '')
        if text:
            # Clean up text - remove footnote markers like [1], [2]
            import re
            text = re.sub(r'\[\d+\]', '', text).strip()
            lines.append(text)
            lines.append("")

    # Write file
    filename = os.path.join(output_dir, f"Kuran_{nuzul_order}.txt")
    with open(filename, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))

    print(f"  Created: Kuran_{nuzul_order}.txt ({len(verses)} ayets)")
    return True

def main():
    output_dir = r"c:\Users\pc\Downloads\RapidReader\assets\books"

    # Process surahs 11-114 (first 10 already done)
    for nuzul_order in range(11, 115):
        mushaf_number = NUZUL_ORDER[nuzul_order - 1]
        create_surah_file(nuzul_order, mushaf_number, output_dir)

    print("\nDone! Created 104 surah files.")

if __name__ == "__main__":
    main()
