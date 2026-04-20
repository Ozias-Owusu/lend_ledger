// class Customer {
//   String id;
//   String name;
//   String phone;
//   String vehicle;
//   String dateJoined;
//   String loanType;
//
//   Customer({
//     required this.id,
//     required this.name,
//     required this.phone,
//     required this.vehicle,
//     required this.dateJoined,
//     required this.loanType,
//   });
//
//   Map<String, dynamic> toJson() => {
//     "id": id,
//     "name": name,
//     "phone": phone,
//     "vehicle": vehicle,
//     "dateJoined": dateJoined,
//     "loanType": loanType,
//   };
//
//   static Customer fromJson(Map<String, dynamic> json) => Customer(
//     id: json["id"],
//     name: json["name"],
//     phone: json["phone"],
//     vehicle: json["vehicle"],
//     dateJoined: json["dateJoined"],
//     loanType: json["loanType"],
//   );
// }

class Customer {
  String id;
  String name;
  String phone;
  String ghanaCardNumber;
  String licenseIdNumber;

  String? ghanaCardFrontImage;
  String? ghanaCardBackImage;
  String? licenseFrontImage;
  String? licenseBackImage;
  String? profilePicture;

  String dateJoined;
  String? loanType;
  List<Map<String, dynamic>> dailyLoans;
  List<Map<String, dynamic>> softLoans;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.ghanaCardNumber,
    required this.licenseIdNumber,
    this.ghanaCardFrontImage,
    this.ghanaCardBackImage,
    this.licenseFrontImage,
    this.licenseBackImage,
    this.profilePicture,
    required this.dateJoined,
    this.loanType,
    this.dailyLoans = const [],
    this.softLoans = const [],
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "phone": phone,
    "ghanaCardNumber": ghanaCardNumber,
    "licenseIdNumber": licenseIdNumber,
    "ghanaCardFrontImage": ghanaCardFrontImage,
    "ghanaCardBackImage": ghanaCardBackImage,
    "licenseFrontImage": licenseFrontImage,
    "licenseBackImage": licenseBackImage,
    "profilePicture": profilePicture,
    "dateJoined": dateJoined,
    "loanType": loanType,
    "dailyLoans": dailyLoans,
    "softLoans": softLoans,
  };

  static Customer fromJson(Map<String, dynamic> json) => Customer(
    id: json["id"],
    name: json["name"],
    phone: json["phone"],
    ghanaCardNumber: json["ghanaCardNumber"] ?? "",
    licenseIdNumber: json["licenseIdNumber"] ?? "",
    ghanaCardFrontImage: json["ghanaCardFrontImage"],
    ghanaCardBackImage: json["ghanaCardBackImage"],
    licenseFrontImage: json["licenseFrontImage"],
    licenseBackImage: json["licenseBackImage"],
    profilePicture: json["profilePicture"],
    dateJoined: json["dateJoined"],
    loanType: json["loanType"],
    dailyLoans: List<Map<String, dynamic>>.from(json["dailyLoans"] ?? const []),
    softLoans: List<Map<String, dynamic>>.from(json["softLoans"] ?? const []),
  );

  static Customer fromApiJson(Map<String, dynamic> json) {
    final countryCode = (json["countryCode"] ?? "").toString().trim();
    final phone = (json["phoneNumber"] ?? "").toString().trim();
    final fullPhone = "$countryCode$phone";
    return Customer(
      id: (json["id"] ?? "").toString(),
      name: (json["fullName"] ?? "").toString(),
      phone: fullPhone,
      ghanaCardNumber: (json["ghanaCardNumber"] ?? "").toString(),
      licenseIdNumber: (json["licenseIdNumber"] ?? "").toString(),
      ghanaCardFrontImage: json["ghanaCardImage"] as String?,
      ghanaCardBackImage: null,
      licenseFrontImage: json["licenseIdImage"] as String?,
      licenseBackImage: null,
      profilePicture: json["profilePicture"] as String?,
      dateJoined: (json["dateJoined"] ?? DateTime.now().toIso8601String()).toString(),
      loanType: null,
      dailyLoans: List<Map<String, dynamic>>.from(json["dailyLoans"] ?? const []),
      softLoans: List<Map<String, dynamic>>.from(json["softLoans"] ?? const []),
    );
  }

  double getOutstandingBalanceFromApiLoans() {
    double total = 0.0;
    for (final loan in dailyLoans) {
      final status = (loan["status"] ?? "").toString().toLowerCase();
      if (status == "active") {
        final amount = loan["totalRepayableAmount"];
        if (amount is num) total += amount.toDouble();
      }
    }
    for (final loan in softLoans) {
      final status = (loan["status"] ?? "").toString().toLowerCase();
      if (status == "active") {
        final amount = loan["totalRepayableAmount"];
        if (amount is num) total += amount.toDouble();
      }
    }
    return total;
  }

  String get firstInitial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return "?";
    return trimmed[0].toUpperCase();
  }
}
