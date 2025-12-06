class User {
  String id;
  String email;
  String password;

  User({required this.id, required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    "id": id,
    "email": email,
    "password": password,
  };

  static User fromJson(Map<String, dynamic> json) => User(
    id: json["id"],
    email: json["email"],
    password: json["password"],
  );
}
