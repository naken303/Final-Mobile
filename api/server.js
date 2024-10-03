const express = require('express');
const cors = require('cors');
const fs = require('fs');
const multer = require('multer');
const path = require('path');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

const dbPath = './db.json';

const readDB = () => {
  const data = fs.readFileSync(dbPath, 'utf8');
  return JSON.parse(data);
};

const writeDB = async (data) => {
  try {
    await fs.promises.writeFile(dbPath, JSON.stringify(data, null, 2), 'utf8');
  } catch (error) {
    console.error('Error writing to the database file:', error);
    throw new Error('Failed to update the database');
  }
};

// User routes
app.get('/users/all', (req, res) => {
  const db = readDB();
  res.json(db.users);
});

app.get('/users', (req, res) => {
  const { username, password } = req.query;
  const db = readDB();
  const user = db.users.find(u => u.username === username && u.password === password);
  user ? res.json(user) : res.status(401).json({ error: 'Invalid credentials' });
});

app.post('/users/register', async (req, res) => {
  const { username, password, role } = req.body;
  const db = readDB();
  const existingUser = db.users.find(u => u.username === username);
  if (existingUser) return res.status(400).json({ error: 'User already exists' });
  
  const newUser = { user_id: db.users.length + 1, username, password, role, borrowed_books: [] };
  db.users.push(newUser);
  await writeDB(db);
  res.status(201).json(newUser);
});

app.delete('/users/:userId', async (req, res) => {
  const { userId } = req.params;
  const db = readDB();
  const userIndex = db.users.findIndex(u => u.user_id === parseInt(userId));
  if (userIndex === -1) return res.status(404).json({ error: 'User not found' });

  db.users.splice(userIndex, 1);
  try {
    await writeDB(db);
    res.status(200).json({ message: 'User deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

// Book routes
app.get('/books', (req, res) => {
  const db = readDB();
  const searchQuery = req.query.title || '';
  const filteredBooks = db.books.filter(book =>
    book.title.toLowerCase().includes(searchQuery.toLowerCase())
  );
  res.json(filteredBooks);
});

app.post('/books', async (req, res) => {
  const { book_id, title, author, description, isbn, catagory, cover_image, copies } = req.body;
  const db = readDB();
  
  const newBook = {
    book_id,
    title,
    author,
    description,
    isbn,
    catagory,
    cover_image,
    copies
  };

  db.books.push(newBook);
  try {
    await writeDB(db);
    res.status(201).json({ message: 'Book added successfully', book: newBook });
  } catch (error) {
    res.status(500).json({ error: 'Failed to add book' });
  }
});


app.patch('/books/:bookId/copies/:copyId', async (req, res) => {
  const { bookId, copyId } = req.params;
  const { status, borrowed_by_user_id, due_date, return_date } = req.body;
  const db = readDB();

  const book = db.books.find(b => b.book_id === bookId);
  if (!book) return res.status(404).json({ error: 'Book not found' });

  const copy = book.copies.find(c => c.book_copy_id === copyId);
  if (!copy) return res.status(404).json({ error: 'Copy not found' });

  copy.status = status !== undefined ? status : copy.status;
  copy.borrowed_by_user_id = borrowed_by_user_id !== undefined ? borrowed_by_user_id : copy.borrowed_by_user_id;
  copy.due_date = due_date !== undefined ? due_date : copy.due_date;
  copy.return_date = return_date !== undefined ? return_date : copy.return_date;

  try {
    await writeDB(db);
    res.status(200).json({ message: 'Copy status updated successfully', book });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update the database' });
  }
});

app.patch('/books/:bookId', async (req, res) => {
  const { bookId } = req.params;
  const { title, author, description, isbn, catagory, cover_image } = req.body;
  const db = readDB();

  const book = db.books.find(b => b.book_id === bookId);
  if (!book) return res.status(404).json({ error: 'Book not found' });

  if (cover_image && cover_image !== book.cover_image) deleteImage(book.cover_image);

  book.title = title || book.title;
  book.author = author || book.author;
  book.description = description || book.description;
  book.isbn = isbn || book.isbn;
  book.catagory = catagory || book.catagory;
  book.cover_image = cover_image || book.cover_image;

  try {
    await writeDB(db);
    res.status(200).json({ message: 'Book updated successfully', book });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update the book' });
  }
});

app.delete('/books/:bookId/copies/:copyId', async (req, res) => {
  const { bookId, copyId } = req.params;
  const db = readDB();

  const book = db.books.find(b => b.book_id === bookId);
  if (!book) return res.status(404).json({ error: 'Book not found' });

  const copyIndex = book.copies.findIndex(c => c.book_copy_id === copyId);
  if (copyIndex === -1) return res.status(404).json({ error: 'Copy not found' });

  book.copies.splice(copyIndex, 1);
  try {
    await writeDB(db);
    res.status(200).json({ message: 'Book copy deleted successfully', book });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete book copy' });
  }
});

app.delete('/books/:bookId', async (req, res) => {
  const { bookId } = req.params;
  const db = readDB();
  const bookIndex = db.books.findIndex(b => b.book_id === bookId);

  if (bookIndex === -1) return res.status(404).json({ error: 'Book not found' });

  db.books.splice(bookIndex, 1);
  try {
    await writeDB(db);
    res.status(200).json({ message: 'Book deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete the book' });
  }
});

// File upload and image handling
const storage = multer.diskStorage({
  destination: './uploads',
  filename: (req, file, cb) => {
    cb(null, file.fieldname + '-' + Date.now() + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 1000000 },
  fileFilter: (req, file, cb) => {
    const filetypes = /jpeg|jpg|png|gif/;
    const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = filetypes.test(file.mimetype);
    extname && mimetype ? cb(null, true) : cb('Error: Images Only!');
  }
}).single('coverImage');

app.post('/upload', (req, res) => {
  upload(req, res, (err) => {
    if (err) res.status(400).json({ error: err });
    else if (!req.file) res.status(400).json({ error: 'No file selected' });
    else res.status(200).json({ fileName: req.file.filename, filePath: `../assets/images/${req.file.filename}` });
  });
});

const deleteImage = (fileName) => {
  const filePath = `../assets/images/${fileName}`;
  fs.unlink(filePath, (err) => {
    if (err) console.error('Error deleting image:', err);
    else console.log('Image successfully deleted:', fileName);
  });
};

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
