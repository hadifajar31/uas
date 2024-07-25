import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import 'package:uas/models/api_response.dart';
import 'package:uas/models/user.dart';

import 'package:uas/services/user_service.dart';

import '../constant.dart';

import 'login.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  User? user;
  bool loading = true;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController txtNameController = TextEditingController();

  Future<void> getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Get user detail
  void getUser() async {
    ApiResponse response = await getUserDetail();
    if (response.error == null) {
      setState(() {
        user = response.data as User;
        loading = false;
        txtNameController.text = user!.name ?? '';
      });
    } else if (response.error == unauthorized) {
      logout().then((value) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${response.error}'),
      ));
    }
  }

  // Update profile
  void updateProfile() async {
    setState(() {
      loading = true;
    });
    String? image = _imageFile == null ? null : getStringImage(_imageFile!);
    ApiResponse response = await updateUser(txtNameController.text, image);

    setState(() {
      loading = false;
    });
    if (response.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${response.data}'),
      ));
    } else if (response.error == unauthorized) {
      logout().then((value) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${response.error}'),
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.only(top: 40, left: 40, right: 40),
      child: ListView(
        children: [
          Center(
            child: GestureDetector(
              onTap: getImage,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  image: _imageFile == null
                      ? user?.image != null
                          ? DecorationImage(
                              image: NetworkImage('${user!.image}'),
                              fit: BoxFit.cover,
                            )
                          : null
                      : DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        ),
                  color: Colors.amber,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Form(
            key: formKey,
            child: TextFormField(
              decoration: kInputDecoration('Name'),
              controller: txtNameController,
              validator: (val) => val!.isEmpty ? 'Invalid Name' : null,
            ),
          ),
          const SizedBox(height: 20),
          kTextButton('Update', () {
            if (formKey.currentState!.validate()) {
              setState(() {
                loading = true;
              });
              updateProfile();
            }
          }),
        ],
      ),
    );
  }
}
