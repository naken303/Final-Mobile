import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

class User {
    int userId;
    String username;
    String password;
    String role;

    User({
        required this.userId,
        required this.username,
        required this.password,
        required this.role,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        userId: json["user_id"],
        username: json["username"],
        password: json["password"],
        role: json["role"],
    );

    Map<String, dynamic> toJson() => {
        "user_id": userId,
        "username": username,
        "password": password,
        "role": role,
    };
}
