import 'dart:convert';
import 'dart:io'; // For File handling
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:library_application/model/books.dart'; // Assuming the Book model is imported

class EditBookPage extends StatefulWidget {
  final Book book;

  const EditBookPage({Key? key, required this.book}) : super(key: key);

  @override
  _EditBookPageState createState() => _EditBookPageState();
}

class _EditBookPageState extends State<EditBookPage> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _descriptionController;
  late TextEditingController _isbnController;
  late TextEditingController _categoryController;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book.title);
    _authorController = TextEditingController(text: widget.book.author);
    _descriptionController = TextEditingController(text: widget.book.description);
    _isbnController = TextEditingController(text: widget.book.isbn);
    _categoryController = TextEditingController(text: widget.book.catagory);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _isbnController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateBook() async {
    String? newCoverImage;

    // If an image is selected, upload it first
    if (_selectedImage != null) {
      final uploadResponse = await uploadImage(_selectedImage!);
      if (uploadResponse != null) {
        newCoverImage = uploadResponse; // The uploaded file name from server
      } else {
        // Handle the image upload error
        print("Image upload failed");
        return;
      }
    }

    // Now update the book details with the new image (if uploaded)
    final response = await http.patch(
      Uri.parse('http://192.168.1.5:3000/books/${widget.book.bookId}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': _titleController.text,
        'author': _authorController.text,
        'description': _descriptionController.text,
        'isbn': _isbnController.text,
        'catagory': _categoryController.text,
        'cover_image': newCoverImage ?? widget.book.coverImage, // Use new or old image
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
    } else {
      // Handle update error
      print('Failed to update book');
    }
  }

  // Upload image function
  Future<String?> uploadImage(File imageFile) async {
    final uri = Uri.parse('http://192.168.1.5:3000/upload');
    var request = http.MultipartRequest('POST', uri);
    var multipartFile = await http.MultipartFile.fromPath('coverImage', imageFile.path);
    request.files.add(multipartFile);

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await http.Response.fromStream(response);
      var result = jsonDecode(responseData.body);
      return result['fileName']; // Return the new image filename
    } else {
      print('Image upload failed');
      return null;
    }
  }


  // Upload Image Function
  Future<Map<String, dynamic>?> _uploadImage(File imageFile) async {
    var request = http.MultipartRequest('POST', Uri.parse('http://192.168.1.5:3000/upload'));
    request.files.add(await http.MultipartFile.fromPath('coverImage', imageFile.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await http.Response.fromStream(response);
      return jsonDecode(responseBody.body);
    } else {
      print('Failed to upload image');
      return null;
    }
  }

  Future<void> _deleteBook() async {
    final response = await http.delete(
      Uri.parse('http://192.168.1.5:3000/books/${widget.book.bookId}'),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      print('Failed to delete book: ${response.statusCode}');
    }
  }


  Future<void> _deleteBookCopy(String bookCopyId) async {
  final response = await http.delete(
    Uri.parse('http://192.168.1.5:3000/books/${widget.book.bookId}/copies/$bookCopyId'),
  );

  if (response.statusCode == 200) {
    setState(() {
      widget.book.copies.removeWhere((copy) => copy.bookCopyId == bookCopyId); // Remove from UI after success
    });
  } else {
    // Handle delete error
    print('Failed to delete book copy');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Book'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteBook, // Delete book
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image preview
              Center(
                child: GestureDetector(
                  onTap: _pickImage, // Pick new image
                  child: _selectedImage == null
                      ? Image.asset('assets/images/${widget.book.coverImage}', height: 200)
                      : Image.file(_selectedImage!, height: 200),
                ),
              ),
              const SizedBox(height: 16),
              // Title input
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              // Author input
              TextField(
                controller: _authorController,
                decoration: InputDecoration(labelText: 'Author'),
              ),
              const SizedBox(height: 16),
              // Description input
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              // ISBN input
              TextField(
                controller: _isbnController,
                decoration: InputDecoration(labelText: 'ISBN'),
              ),
              const SizedBox(height: 16),
              // Category input
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              // Book Copies List
              const Text(
                'Book Copies',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: widget.book.copies.length,
                itemBuilder: (context, index) {
                  final copy = widget.book.copies[index];
                  return ListTile(
                    title: Text(copy.bookCopyId),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteBookCopy(copy.bookCopyId), // Call delete function
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Confirm button
              Center(
                child: ElevatedButton(
                  onPressed: _updateBook, // Confirm book update
                  child: const Text('Confirm Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
