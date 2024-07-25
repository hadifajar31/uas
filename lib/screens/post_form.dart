import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uas/constant.dart';
import 'package:uas/models/api_response.dart';
import 'package:uas/models/post.dart';
import 'package:uas/services/post_service.dart';
import 'package:uas/services/user_service.dart';
import 'login.dart';

class PostForm extends StatefulWidget {
  final Post? post;
  final String? title;

  const PostForm({
    this.post,
    this.title,
    super.key
  });

  @override
  _PostFormState createState() => _PostFormState();
}

class _PostFormState extends State<PostForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _txtControllerBody = TextEditingController();
  bool _loading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _createPost() async {
    setState(() {
      _loading = true;
    });

    String? image = _imageFile == null ? null : getStringImage(_imageFile!);
    ApiResponse response = await createPost(_txtControllerBody.text, image);

    if (response.error == null) {
      Navigator.of(context).pop();
    } else if (response.error == unauthorized) {
      logout().then((value) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()), 
          (route) => false
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${response.error}'),
      ));
      setState(() {
        _loading = false;
      });
    }
  }

  void _editPost(int postId) async {
    setState(() {
      _loading = true;
    });

    ApiResponse response = await editPost(postId, _txtControllerBody.text);
    if (response.error == null) {
      Navigator.of(context).pop();
    } else if (response.error == unauthorized) {
      logout().then((value) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()), 
          (route) => false
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${response.error}'),
      ));
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _txtControllerBody.text = widget.post!.body ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Post Form'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (widget.post == null)
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 200,
                    decoration: BoxDecoration(
                      image: _imageFile == null
                          ? null
                          : DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.image, size: 50, color: Colors.black38),
                        onPressed: getImage,
                      ),
                    ),
                  ),
                Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: _txtControllerBody,
                      keyboardType: TextInputType.multiline,
                      maxLines: 9,
                      validator: (val) => val!.isEmpty ? 'Post body is required' : null,
                      decoration: const InputDecoration(
                        hintText: "Post body...",
                        border: OutlineInputBorder(
                          borderSide: BorderSide(width: 1, color: Colors.black38),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: kTextButton('Post', () {
                    if (_formKey.currentState!.validate()) {
                      if (widget.post == null) {
                        _createPost();
                      } else {
                        _editPost(widget.post!.id ?? 0);
                      }
                    }
                  }),
                ),
              ],
            ),
    );
  }
}
