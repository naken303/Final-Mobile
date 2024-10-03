import 'dart:convert';

Books booksFromJson(String str) => Books.fromJson(json.decode(str));

String booksToJson(Books data) => json.encode(data.toJson());

class Books {
    List<Book> books;

    Books({
        required this.books,
    });

    factory Books.fromJson(Map<String, dynamic> json) => Books(
        books: List<Book>.from(json["books"].map((x) => Book.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "books": List<dynamic>.from(books.map((x) => x.toJson())),
    };
}

class Book {
    String bookId;
    String title;
    String author;
    String description;
    String isbn;
    String catagory;
    String coverImage;
    List<Copy> copies;

    Book({
        required this.bookId,
        required this.title,
        required this.author,
        required this.description,
        required this.isbn,
        required this.catagory,
        required this.coverImage,
        required this.copies,
    });

    factory Book.fromJson(Map<String, dynamic> json) => Book(
        bookId: json["book_id"],
        title: json["title"],
        author: json["author"],
        description: json["description"],
        isbn: json["isbn"],
        catagory: json["catagory"],
        coverImage: json["cover_image"],
        copies: List<Copy>.from(json["copies"].map((x) => Copy.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "book_id": bookId,
        "title": title,
        "author": author,
        "description": description,
        "isbn": isbn,
        "catagory": catagory,
        "cover_image": coverImage,
        "copies": List<dynamic>.from(copies.map((x) => x.toJson())),
    };
}

class Copy {
    String bookCopyId;
    String status;
    int? borrowedByUserId;
    DateTime? dueDate;
    DateTime? returnDate;

    Copy({
        required this.bookCopyId,
        required this.status,
        required this.borrowedByUserId,
        required this.dueDate,
        this.returnDate,
    });

    factory Copy.fromJson(Map<String, dynamic> json) => Copy(
        bookCopyId: json["book_copy_id"],
        status: json["status"],
        borrowedByUserId: json["borrowed_by_user_id"],
        dueDate: json["due_date"] == null ? null : DateTime.parse(json["due_date"]),
        returnDate: json["return_date"] == null ? null : DateTime.parse(json["return_date"]),
    );

    Map<String, dynamic> toJson() => {
        "book_copy_id": bookCopyId,
        "status": status,
        "borrowed_by_user_id": borrowedByUserId,
        "due_date": "${dueDate!.year.toString().padLeft(4, '0')}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}",
        "return_date": "${returnDate!.year.toString().padLeft(4, '0')}-${returnDate!.month.toString().padLeft(2, '0')}-${returnDate!.day.toString().padLeft(2, '0')}",
    };
}
