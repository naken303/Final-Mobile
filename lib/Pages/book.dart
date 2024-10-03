import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:library_application/Pages/addbook.dart';
import 'package:library_application/Pages/edit.dart';
import 'package:library_application/Pages/home.dart';
import 'package:library_application/Pages/transcation.dart';
import 'package:library_application/Pages/user.dart';
import 'dart:convert';
import 'package:library_application/model/books.dart';
import 'dart:async';

class BookGridScreen extends StatefulWidget {
  final String userName;
  final int userId;

  const BookGridScreen({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  _BookGridScreenState createState() => _BookGridScreenState();
}

class _BookGridScreenState extends State<BookGridScreen> {
  late Future<List<Book>> booksFuture;
  String searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    booksFuture = fetchBooks(); // Initially load all books
  }

  Future<List<Book>> fetchBooks([String query = '']) async {
    // Modify the URL to accept the search query
    final response = await http.get(Uri.parse('http://192.168.1.5:3000/books?title=$query'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((book) => Book.fromJson(book)).toList();
    } else {
      throw Exception('Failed to load books');
    }
  }

  void _onSearchChanged(String query) {
    // Debounce the search input
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        searchQuery = query;
        booksFuture = fetchBooks(query); // Fetch books based on the query
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Books',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
      backgroundColor: const Color.fromARGB(255, 255, 247, 242),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 247, 242),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text(
              "Welcome' ${widget.userName}",
              style: const TextStyle(color: Colors.black),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.black),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AddBookPage()));
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(), // Add search bar widget
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Book>>(
                future: booksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    return _buildBookGrid(snapshot.data!);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Book name',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onChanged: _onSearchChanged, // Trigger search when query changes
    );
  }

  Widget _buildBookGrid(List<Book> books) {
    return GridView.builder(
      itemCount: books.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.45,
      ),
      itemBuilder: (context, index) {
        final book = books[index];
        return GestureDetector(
          onTap: () {
            _showBookDetails(context, book);
          },
          child: _buildBookCard(book),
        );
      },
    );
  }

  Widget _buildBookCard(Book book) {
    int availableCopies = book.copies.where((copy) => copy.status == 'available').length;
    int borrowedCopies = book.copies.where((copy) => copy.status == 'borrowed').length;

    // Check for default image
    String coverImage = book.coverImage.isNotEmpty ? book.coverImage : 'assets/images/default.jpg';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              coverImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to default image in case the file is not found
                return Image.asset('assets/images/${coverImage}', fit: BoxFit.cover);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              Text(
                book.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Available: $availableCopies',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Booked: $borrowedCopies',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBookDetails(BuildContext context, Book? book) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: book != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row for Edit icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.brown),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditBookPage(book: book),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.asset(
                              'assets/images/${book.coverImage}',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            book.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            book.author,
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text('Available'),
                                const SizedBox(height: 5),
                                Text(
                                  '${book.copies.where((copy) => copy.status == "available").length}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Column(
                              children: [
                                Text('Language'),
                                SizedBox(height: 5),
                                Text(
                                  'English',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('Booked'),
                                const SizedBox(height: 5),
                                Text(
                                  '${book.copies.where((copy) => copy.status == "borrowed").length}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Books Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          controller: scrollController,
                          shrinkWrap: true,
                          itemCount: book.copies.length,
                          itemBuilder: (context, index) {
                            final copy = book.copies[index];
                            return ListTile(
                              title: Text('ID: ${copy.bookCopyId}'),
                              subtitle: Text('Status: ${copy.status}'),
                              tileColor: Colors.grey[100],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  : const Center(child: Text('No book selected')),
            ),
          ),
        );
      },
    ),
  );
}

  
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          Navigator.push(context, MaterialPageRoute(builder: (context) => DashboardScreen(userName: widget.userName, userId: widget.userId,)));
          break;
        case 1:
            // already here boss.
          break;
        case 2:
          Navigator.push(context, MaterialPageRoute(builder: (context) => Transaction(userName: widget.userName, userId: widget.userId)));
          break;
        case 3:
          Navigator.push(context, MaterialPageRoute(builder: (context) => UserListScreen(userName: widget.userName, userId: widget.userId)));
          break;
      }
    });
  }
}


