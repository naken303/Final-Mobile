import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:library_application/Pages/book.dart';
import 'package:library_application/Pages/home.dart';
import 'package:library_application/Pages/user.dart';
import 'package:library_application/model/books.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class Transaction extends StatefulWidget {

  final String userName;
  final int userId;

  const Transaction({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  _TransactionState createState() => _TransactionState();
}

class _TransactionState extends State<Transaction> {
  late Future<List<Book>> booksFuture;
  String searchQuery = ''; // For search query
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    booksFuture = fetchBooks(); // Fetch books on init
  }

  Future<List<Book>> fetchBooks([String query = '']) async {
    final response = await http.get(Uri.parse('http://192.168.1.5:3000/books'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      List<Book> allBooks = jsonResponse.map((book) => Book.fromJson(book)).toList();

      if (query.isNotEmpty) {
        return allBooks.where((book) => book.copies.any((copy) => copy.bookCopyId.contains(query))).toList();
      }

      return allBooks;
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        searchQuery = query;
        booksFuture = fetchBooks(query);
      });
    });
  }

  void _returnBook(String bookId, String bookCopyId) async {
  final response = await http.patch(
    Uri.parse('http://192.168.1.5:3000/books/$bookId/copies/$bookCopyId'),
    headers: <String, String>{'Content-Type': 'application/json'},
    body: jsonEncode(<String, dynamic>{
      'borrowed_by_user_id': null, // Clear the user ID
      'status': 'available', // Mark the book as available
      'due_date': null, // Clear the due (borrow) date
      'return_date': null, // Clear the return deadline
    }),
  );

  if (response.statusCode == 200) {
    print('Book returned successfully');
    setState(() {
      booksFuture = fetchBooks(); // Refresh the book list after returning
    });
  } else {
    print('Failed to return book');
  }
}


  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 247, 242),
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
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 247, 242),
        automaticallyImplyLeading: false,
        title: const Center(child: Text("Borrow and Return")),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 10),
            _buildBorrowBookButton(), // Add borrow button here
            Divider(height: 32),
            Expanded(
              child: FutureBuilder<List<Book>>(
                future: booksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                    return const Center(child: Text('No transactions found'));
                  } else {
                    return _buildTransactionList(snapshot.data!);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Search bar for searching books
  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search by book id',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onChanged: _onSearchChanged, // Update search query
    );
  }

  // Borrow Book Button
  Widget _buildBorrowBookButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            _showBorrowModal(context);
          },
          icon: const Icon(Icons.add_circle_outline, color: Colors.white),
          label: const Text("Borrow Book", style: TextStyle(color: Colors.white),),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown, // Fixed from primary to backgroundColor
          ),
        ),
      ],
    );
  }

  // Modal Bottom Sheet for Borrow Book form
  void _showBorrowModal(BuildContext context) {
    String userId = '';
    String bookId = ''; // You need to handle bookId as well
    String bookCopyId = '';
    DateTime? startDate;
    DateTime? returnDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text(
                      'Borrow Book',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(labelText: 'User ID'),
                      onChanged: (value) {
                        userId = value;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Book ID'), // Book ID field
                      onChanged: (value) {
                        bookId = value;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Book Copy ID'),
                      onChanged: (value) {
                        bookCopyId = value;
                      },
                    ),
                    const SizedBox(height: 10),
                    // Start Date
                    _buildDateField(
                      label: 'Start Date',
                      selectedDate: startDate,
                      onSelectDate: (pickedDate) {
                        setState(() {
                          startDate = pickedDate;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    // Return Date (Deadline)
                    _buildDateField(
                      label: 'Return Date (Deadline)',
                      selectedDate: returnDate,
                      onSelectDate: (pickedDate) {
                        setState(() {
                          returnDate = pickedDate;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Handle the borrow action
                        _borrowBook(userId, bookId, bookCopyId, startDate, returnDate);
                        Navigator.pop(context); // Close modal after submitting
                      },
                      child: const Text('Borrow'),
                    ),
                  ],
                ),
              ),
            );
      },
    );
  }

  // Date picker field for selecting dates
  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onSelectDate,
  }) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null) {
          onSelectDate(pickedDate);
        }
      },
      controller: TextEditingController(
        text: selectedDate != null ? DateFormat('dd/MM/yyyy').format(selectedDate) : '',
      ),
    );
  }

  void _borrowBook(String userId, String bookId, String bookCopyId, DateTime? borrowDate, DateTime? returnDeadline) async {
    if (userId.isEmpty || bookId.isEmpty || bookCopyId.isEmpty || borrowDate == null || returnDeadline == null) {
      // Handle invalid inputs
      print('Invalid input');
      return;
    }

    final response = await http.patch(
      Uri.parse('http://192.168.1.5:3000/books/$bookId/copies/$bookCopyId'), // Correctly use bookId and copyId
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'borrowed_by_user_id': int.parse(userId),
        'status': 'borrowed',
        'due_date': borrowDate.toIso8601String(), // due_date refers to the borrow date
        'return_date': returnDeadline.toIso8601String(), // return_date refers to the return deadline
      }),
    );

    if (response.statusCode == 200) {
      print('Book borrowed successfully');
      setState(() {
        booksFuture = fetchBooks(); // Refresh the book list
      });
    } else {
      print('Failed to borrow book');
    }
  }


  // List of borrowed transactions
  Widget _buildTransactionList(List<Book> books) {
    List<Widget> transactionWidgets = [];

    for (var book in books) {
      for (var copy in book.copies) {
        if (copy.status == 'borrowed') {
          transactionWidgets.add(_buildTransactionCard(book, copy));
        }
      }
    }

    return ListView(
      children: transactionWidgets,
    );
  }

  // Each transaction card widget
  Widget _buildTransactionCard(Book book, Copy copy) {
    bool isOverdue = copy.returnDate != null && DateTime.now().isAfter(copy.returnDate!);

    return Card(
      child: ListTile(
        tileColor: Colors.white,
        title: Text(book.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BID: ${copy.bookCopyId}'),
            Text('UID: ${copy.borrowedByUserId != null ? copy.borrowedByUserId.toString() : 'N/A'}'),
            Text('Borrow Date: ${copy.dueDate != null ? DateFormat('dd/MM/yyyy').format(copy.dueDate!) : 'N/A'}'),
            Text('Return Date: ${copy.returnDate != null ? DateFormat('dd/MM/yyyy').format(copy.returnDate!) : 'N/A'}'),
            if (isOverdue)
              Text(
                'Overdue',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            _returnBook(book.bookId, copy.bookCopyId); // Call the return function
          },
          child: const Text('Return'),
        ),
      ),
    );
  }

  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Add your navigation logic here based on the selected index.
      switch (index) {
        case 0:
        Navigator.push(context, MaterialPageRoute(builder: (context) => DashboardScreen(userName: widget.userName, userId: widget.userId)));
          // Navigator.push(context, MaterialPageRoute(builder: (context) => BookGridScreen()));
          break;
        case 1:
          Navigator.push(context, MaterialPageRoute(builder: (context) => BookGridScreen(userName: widget.userName, userId: widget.userId)));
          break;
        case 2:
          // Navigator.push(context, MaterialPageRoute(builder: (context) => Transaction(userName: widget.userName, userId: widget.userId)));
          break;
        case 3:
          Navigator.push(context, MaterialPageRoute(builder: (context) => UserListScreen(userName: widget.userName, userId: widget.userId)));
          break;
      }
    });
  }

}
