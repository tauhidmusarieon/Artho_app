import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? localImagePath; // <-- LOCAL IMAGE VARIABLE

  @override
  void initState() {
    loadLocalImage(); // <-- load saved image on startup
    super.initState();
  }

  // Load saved profile image
  Future<void> loadLocalImage() async {
    final p = await SharedPreferences.getInstance();
    setState(() => localImagePath = p.getString("profileImage"));
  }

  /// ================= Change Name =================
  Future<void> changeName() async {
    TextEditingController name = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Name"),
        content: TextField(
          controller: name,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Name cannot be empty")),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .update({"name": name.text.trim()});

              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Name updated successfully")),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// ================= Change Email =================
  Future<void> changeEmail() async {
    TextEditingController newEmail = TextEditingController();
    TextEditingController password = TextEditingController();
    final user = FirebaseAuth.instance.currentUser!;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Email"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newEmail,
              decoration: const InputDecoration(labelText: "New Email"),
            ),
            TextField(
              controller: password,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (newEmail.text.isEmpty || password.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Fields cannot be empty")),
                );
                return;
              }

              try {
                final cred = EmailAuthProvider.credential(
                  email: user.email!,
                  password: password.text.trim(),
                );
                await user.reauthenticateWithCredential(cred);
                await user.verifyBeforeUpdateEmail(newEmail.text.trim());

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({"email": newEmail.text.trim()});

                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Email verification sent")),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  /// ================= Change Profile Picture (LOCAL) =================
  Future<void> changeProfilePic() async {
    final pick = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pick == null) return;

    final pref = await SharedPreferences.getInstance();
    await pref.setString("profileImage", pick.path);

    setState(() => localImagePath = pick.path);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profile Picture Updated.")));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());

          final data = snap.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundImage: localImagePath != null
                          ? FileImage(File(localImagePath!))
                          : const AssetImage("assets/images/artho_logo.png")
                                as ImageProvider,
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: changeProfilePic,
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.black,
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),
              Center(
                child: Text(
                  data["name"] ?? "",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Center(
                child: Text(
                  data["email"],
                  style: const TextStyle(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 30),

              tile(Icons.person, "Change Name", changeName),
              tile(Icons.email, "Change Email", changeEmail),
              tile(Icons.photo, "Change Profile Picture", changeProfilePic),

              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget tile(icon, text, onTap) => ListTile(
    leading: Icon(icon, size: 26),
    title: Text(text, style: const TextStyle(fontSize: 17)),
    trailing: const Icon(Icons.arrow_forward_ios, size: 17),
    onTap: onTap,
  );
}
