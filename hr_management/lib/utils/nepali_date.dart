class NepaliDate {
  final int year;
  final int month;
  final int day;
  const NepaliDate(this.year, this.month, this.day);

  static const List<String> nepaliMonthsNepali = [
    'बैशाख','जेठ','असार','श्रावण','भाद्र','आश्विन',
    'कार्तिक','मंसिर','पुष','माघ','फाल्गुन','चैत्र',
  ];
  static const List<String> nepaliMonthsEnglish = [
    'Baisakh','Jestha','Asar','Shrawan','Bhadra','Ashwin',
    'Kartik','Mangsir','Poush','Magh','Falgun','Chaitra',
  ];
  static const List<String> weekDaysNepali  = ['आइत','सोम','मंगल','बुध','बिही','शुक्र','शनि'];
  static const List<String> weekDaysEnglish = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

  // Days per BS month for years 2079–2084
  static const Map<int, List<int>> _daysInMonth = {
    2079: [31,32,31,32,31,30,30,30,29,30,29,31],
    2080: [31,32,31,32,31,30,30,29,30,29,30,30],
    2081: [31,31,32,31,31,31,30,29,30,29,30,30],
    2082: [31,32,31,32,31,30,30,30,29,29,30,31],
    2083: [30,32,31,32,31,30,30,30,29,30,29,31],
    2084: [31,31,32,31,31,30,30,30,29,30,30,30],
  };

  // Reference: BS 2081/01/01 = AD 2024/04/13
  static const DateTime _adRef = DateTime(2024, 4, 13);
  static const int _bsRefYear = 2081, _bsRefMonth = 1, _bsRefDay = 1;

  static int _totalDays(int y, int m, int d) {
    int total = 0;
    for (int yr = 2079; yr < y; yr++) {
      for (final days in (_daysInMonth[yr] ?? List.filled(12, 30))) total += days;
    }
    final months = _daysInMonth[y] ?? List.filled(12, 30);
    for (int i = 0; i < m - 1; i++) total += months[i];
    return total + d;
  }

  static int get _refDays => _totalDays(_bsRefYear, _bsRefMonth, _bsRefDay);

  static NepaliDate fromDateTime(DateTime ad) {
    int rem = _refDays + ad.difference(_adRef).inDays;
    int yr = 2079;
    while (true) {
      final months = _daysInMonth[yr];
      if (months == null) break;
      final yrDays = months.fold(0, (s, d) => s + d);
      if (rem <= yrDays) break;
      rem -= yrDays; yr++;
    }
    int mo = 1;
    final months = _daysInMonth[yr] ?? List.filled(12, 30);
    while (mo <= 12 && rem > months[mo - 1]) { rem -= months[mo - 1]; mo++; }
    return NepaliDate(yr, mo, rem);
  }

  static DateTime toDateTime(NepaliDate bs) {
    final diff = _totalDays(bs.year, bs.month, bs.day) - _refDays;
    return _adRef.add(Duration(days: diff));
  }

  int get daysInMonth => (_daysInMonth[year] ?? List.filled(12, 30))[month - 1];
  String get monthNameNepali  => nepaliMonthsNepali[month - 1];
  String get monthNameEnglish => nepaliMonthsEnglish[month - 1];

  NepaliDate get prevMonth => month == 1
      ? NepaliDate(year - 1, 12, 1)
      : NepaliDate(year, month - 1, 1);
  NepaliDate get nextMonth => month == 12
      ? NepaliDate(year + 1, 1, 1)
      : NepaliDate(year, month + 1, 1);

  static String toNepaliNumerals(int n) {
    const d = ['०','१','२','३','४','५','६','७','८','९'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  String get yearNepali => toNepaliNumerals(year);
  String get dayNepali  => toNepaliNumerals(day);
}
