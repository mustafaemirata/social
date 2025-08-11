class AppUser {
  final String uid;
  final String email;
  final String name;
  final String? profileImageUrl;

  AppUser({
    required this.uid, 
    required this.email, 
    required this.name,
    this.profileImageUrl,
  });

  Map<String, dynamic> toJSON() {
    return {
      "uid": uid, 
      "email": email, 
      "name": name,
      "profileImageUrl": profileImageUrl,
    };
  }

  factory AppUser.fromJSON(Map<String, dynamic> jsonUser) {
    return AppUser(
      uid: jsonUser['uid'],
      email: jsonUser['email'],
      name: (jsonUser['name'] ?? '') as String,
      profileImageUrl: jsonUser['profileImageUrl'] as String?,
    );
  }
}