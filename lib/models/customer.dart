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

  String dateJoined;
  String? loanType;

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
    required this.dateJoined,
    this.loanType,
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
    "dateJoined": dateJoined,
    "loanType": loanType,
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
    dateJoined: json["dateJoined"],
    loanType: json["loanType"],
  );
}
