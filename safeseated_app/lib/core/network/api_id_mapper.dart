class ApiIdMapper {
  ApiIdMapper._();

  static final Map<int, String> _intToGuid = {};
  static final Map<String, int> _guidToInt = {};

  static int toInt(String guid) {
    final normalized = guid.toLowerCase();
    final existing = _guidToInt[normalized];
    if (existing != null) return existing;

    var value = 0;
    for (var i = 0; i < normalized.length; i++) {
      value = ((value * 31) + normalized.codeUnitAt(i)) & 0x3fffffff;
    }
    var result = value == 0 ? 1 : value;
    while (_intToGuid.containsKey(result) && _intToGuid[result] != normalized) {
      result = (result + 1) & 0x3fffffff;
    }
    _intToGuid[result] = normalized;
    _guidToInt[normalized] = result;
    return result;
  }

  static String? toGuid(int id) => _intToGuid[id];

  static void remember(int id, String guid) {
    _intToGuid[id] = guid.toLowerCase();
    _guidToInt[guid.toLowerCase()] = id;
  }
}
