//create a model
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? id;
  final String username;
  final String email;
  final String pincode;
  final String password;
  final String phone;

  const UserModel({
    this.id,
    required this.email,
    required this.username,
    required this.pincode,
    required this.password,
    required this.phone,
  });

  toJson() {
    return {
      "Username": username,
      "Email": email,
      "Password": password,
      "Phone Number": phone,
      "Pincode": pincode,
    };
  }

  //Map user fetched from the firebase to usermodel
  factory UserModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    return UserModel(
      email: data["Email"],
      username: data["Username"],
      pincode: data["pincode"],
      password: data["password"],
      phone: data["phone"],
    );
  }
}
