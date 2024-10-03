import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
// import 'package:library_application/model/books.dart'; // Assuming the Book model is imported

class AddBookPage extends StatefulWidget {
  @override
  _AddBookPageState createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final TextEditingController _bookIdController = TextEditingController();  // Add controller for book_id
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _isbnController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  
  File? _selectedImage;
  int _copies = 1;

  @override
  void dispose() {
    _bookIdController.dispose();  // Dispose of book_id controller
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

  List<String> _generateBookCopyIds(String bookId, int count) {
    return List.generate(count, (index) {
      final number = index + 1;
      final runNumber = number.toString().padLeft(2, '0'); // Create 'a01', 'a02', ...
      return '$bookId' + 'a$runNumber';
    });
  }

  Future<void> _addBook() async {
    final String bookId = _bookIdController.text;  // Use user input for book_id
    final List<String> generatedCopies = _generateBookCopyIds(bookId, _copies);

    final response = await http.post(
      Uri.parse('http://192.168.1.5:3000/books'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'book_id': bookId,
        'title': _titleController.text,
        'author': _authorController.text,
        'description': _descriptionController.text,
        'isbn': _isbnController.text,
        'catagory': _categoryController.text,
        'cover_image': _selectedImage != null ? _selectedImage!.path.split('/').last : 'default.jpg',
        'copies': generatedCopies.map((copyId) => {
          'book_copy_id': copyId,
          'status': 'available',
          'borrowed_by_user_id': null,
          'due_date': null,
          'return_date': null
        }).toList()
      }),
    );

    if (response.statusCode == 201) {
      Navigator.pop(context);
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
        title: Text('Add Book'),
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
                  onTap: _pickImage,
                  child: _selectedImage == null
                      ? Image.asset('assets/images/default.jpg', height: 200)
                      : Image.file(_selectedImage!, height: 200),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bookIdController,  // Add input for book_id
                decoration: InputDecoration(labelText: 'Book ID'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _authorController,
                decoration: InputDecoration(labelText: 'Author'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _isbnController,
                decoration: InputDecoration(labelText: 'ISBN'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Copies',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: _copies > 1
                        ? () {
                            setState(() {
                              _copies--;
                            });
                          }
                        : null,
                  ),
                  Text('$_copies'),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        _copies++;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _addBook,
                  child: const Text('Add Book'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
