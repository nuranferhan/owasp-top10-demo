require('dotenv').config();
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const multer = require('multer');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cookieParser = require('cookie-parser');
const session = require('express-session');
const bodyParser = require('body-parser');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'fallback_jwt_secret';

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

app.use(express.static('public'));
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(cookieParser());

app.use(session({
  secret: process.env.SESSION_SECRET || 'fallback_session_secret',
  resave: false,
  saveUninitialized: true,
  cookie: { 
    secure: process.env.COOKIE_SECURE === 'true',
    maxAge: parseInt(process.env.COOKIE_MAX_AGE) || 86400000
  }
}));

const db = new sqlite3.Database(process.env.DB_PATH || './database.db');

db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE,
    password TEXT,
    email TEXT,
    role TEXT DEFAULT 'user',
    profile_pic TEXT
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS posts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    content TEXT,
    author_id INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    post_id INTEGER,
    comment TEXT,
    author TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);
  
  const adminPassword = bcrypt.hashSync(process.env.ADMIN_PASSWORD || 'admin123', parseInt(process.env.BCRYPT_ROUNDS) || 10);
  db.run(`INSERT OR IGNORE INTO users (username, password, email, role) 
        VALUES (?, ?, ?, 'admin')`, [
          process.env.ADMIN_USERNAME || 'admin',
          adminPassword,
          process.env.ADMIN_EMAIL || 'admin@vulnerable.com'
        ]);

  const userPassword = bcrypt.hashSync(process.env.USER_PASSWORD || 'user123', parseInt(process.env.BCRYPT_ROUNDS) || 10);
  db.run(`INSERT OR IGNORE INTO users (username, password, email, role) 
        VALUES (?, ?, ?, 'user')`, [
          process.env.USER_USERNAME || 'user',
          userPassword,
          process.env.USER_EMAIL || 'user@vulnerable.com'
        ]);
});

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
  cb(null, process.env.UPLOAD_PATH || 'public/uploads/')
},
  filename: function (req, file, cb) {
    cb(null, file.originalname)
  }
});

const upload = multer({ storage: storage });

app.get('/', (req, res) => {
  db.all("SELECT * FROM posts ORDER BY created_at DESC", (err, posts) => {
    if (err) {
      return res.status(500).send('Database error');
    }
    res.render('index', { posts: posts, user: req.session.user });
  });
});

app.get('/login', (req, res) => {
  res.render('login');
});

app.post('/login', (req, res) => {
  const { username, password } = req.body;
  
  const query = `SELECT * FROM users WHERE username = '${username}' AND password = '${password}'`;
  
  db.get(query, (err, user) => {
    if (err) {
      return res.status(500).send('Database error: ' + err.message);
    }
    
    if (user) {
      req.session.user = user;
      const token = jwt.sign({ userId: user.id, username: user.username }, JWT_SECRET);
      res.cookie('token', token);
      res.redirect('/dashboard');
    } else {
      res.render('login', { error: 'Invalid credentials' });
    }
  });
});

app.get('/register', (req, res) => {
  res.render('register');
});

app.post('/register', (req, res) => {
  const { username, password, email } = req.body;
  
  const query = `INSERT INTO users (username, password, email) VALUES ('${username}', '${password}', '${email}')`;
  
  db.run(query, function(err) {
    if (err) {
      return res.render('register', { error: 'Registration failed: ' + err.message });
    }
    res.redirect('/login');
  });
});

app.get('/dashboard', (req, res) => {
  if (!req.session.user) {
    return res.redirect('/login');
  }
  
  const userId = req.query.userId || req.session.user.id;
  
  const query = `SELECT * FROM users WHERE id = ${userId}`;
  
  db.get(query, (err, user) => {
    if (err) {
      return res.status(500).send('Database error: ' + err.message);
    }
    res.render('dashboard', { user: user, sessionUser: req.session.user });
  });
});

app.get('/search', (req, res) => {
  const searchTerm = req.query.q;
  
  const query = `SELECT * FROM posts WHERE title LIKE '%${searchTerm}%' OR content LIKE '%${searchTerm}%'`;
  
  db.all(query, (err, posts) => {
    if (err) {
      return res.status(500).send('Database error: ' + err.message);
    }
    res.render('search', { posts: posts, searchTerm: searchTerm, user: req.session.user });
  });
});

app.get('/post/:id', (req, res) => {
  const postId = req.params.id;
  
  db.get("SELECT * FROM posts WHERE id = ?", [postId], (err, post) => {
    if (err) {
      return res.status(500).send('Database error');
    }
    
    db.all("SELECT * FROM comments WHERE post_id = ?", [postId], (err, comments) => {
      if (err) {
        return res.status(500).send('Database error');
      }
      res.render('post', { post: post, comments: comments, user: req.session.user });
    });
  });
});

app.post('/comment', (req, res) => {
  const { postId, comment, author } = req.body;
  
  const query = `INSERT INTO comments (post_id, comment, author) VALUES (${postId}, '${comment}', '${author}')`;
  
  db.run(query, function(err) {
    if (err) {
      return res.status(500).send('Database error: ' + err.message);
    }
    res.redirect(`/post/${postId}`);
  });
});

app.get('/admin', (req, res) => {
  if (!req.session.user || req.session.user.role !== 'admin') {
    return res.status(403).send('Access denied');
  }
  
  db.all("SELECT * FROM users", (err, users) => {
    if (err) {
      return res.status(500).send('Database error');
    }
    res.render('admin', { users: users, user: req.session.user });
  });
});

app.post('/admin/delete-user', (req, res) => {
  const { userId } = req.body;
  
  const query = `DELETE FROM users WHERE id = ${userId}`;
  
  db.run(query, function(err) {
    if (err) {
      return res.status(500).send('Database error: ' + err.message);
    }
    res.redirect('/admin');
  });
});

app.get('/profile', (req, res) => {
  if (!req.session.user) {
    return res.redirect('/login');
  }
  res.render('profile', { user: req.session.user });
});

app.post('/upload', upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).send('No file uploaded');
  }
  
  const fileUrl = `/uploads/${req.file.filename}`;
  res.send(`File uploaded successfully: <a href="${fileUrl}">${fileUrl}</a>`);
});

app.get('/file/:filename', (req, res) => {
  const filename = req.params.filename;
  const filePath = path.join(__dirname, 'public/uploads', filename);
  
  if (filename.includes('../') || filename.includes('..\\')) {
    return res.status(400).send('Invalid filename');
  }
  
  res.sendFile(filePath);
});

app.get('/xml', (req, res) => {
  const xmlData = req.query.xml;
  
  if (xmlData) {
    try {
      const result = eval(`(${xmlData})`);
      res.send(`XML processed: ${result}`);
    } catch (error) {
      res.status(400).send('XML processing error: ' + error.message);
    }
  } else {
    res.render('xml');
  }
});

app.get('/redirect', (req, res) => {
  const url = req.query.url;
  if (url) {
    res.redirect(url);
  } else {
    res.send('Please provide a URL parameter');
  }
});

app.post('/change-password', (req, res) => {
  const { newPassword } = req.body;
  const userId = req.session.user.id;
  
  const query = `UPDATE users SET password = '${newPassword}' WHERE id = ${userId}`;
  
  db.run(query, function(err) {
    if (err) {
      return res.status(500).send('Database error: ' + err.message);
    }
    res.send('Password changed successfully');
  });
});

app.get('/api/users', (req, res) => {
  const token = req.cookies.token;
  
  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    db.all("SELECT id, username, email FROM users", (err, users) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }
      res.json(users);
    });
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

app.get('/logout', (req, res) => {
  req.session.destroy();
  res.clearCookie('token');
  res.redirect('/');
});

app.listen(PORT, () => {
  console.log(`Vulnerable app running on http://localhost:${PORT}`);
  console.log('OWASP Top 10 vulnerabilities included:');
  console.log('1. SQL Injection');
  console.log('2. Cross-Site Scripting (XSS)');
  console.log('3. Insecure Direct Object References');
  console.log('4. Cross-Site Request Forgery (CSRF)');
  console.log('5. Security Misconfiguration');
  console.log('6. Insecure File Upload');
  console.log('7. Path Traversal');
  console.log('8. XML External Entities (XXE)');
  console.log('9. Unvalidated Redirects');
  console.log('10. Broken Authentication');
});