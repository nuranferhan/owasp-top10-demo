const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcrypt');

const db = new sqlite3.Database('./vulnerable-app/database.db');

db.serialize(() => {
  // Demo posts oluştur
  const posts = [
    {
      title: "Welcome to Vulnerable Blog",
      content: "This is a demo blog post for testing purposes. You can search for posts and leave comments.",
      author_id: 1
    },
    {
      title: "Security Testing Guide",
      content: "This application contains intentional vulnerabilities for educational purposes. Please test responsibly.",
      author_id: 2
    },
    {
      title: "OWASP Top 10 Demo",
      content: "This post demonstrates various security vulnerabilities. Try searching with special characters!",
      author_id: 1
    }
  ];

  posts.forEach(post => {
    db.run("INSERT INTO posts (title, content, author_id) VALUES (?, ?, ?)", 
           [post.title, post.content, post.author_id]);
  });

  // Demo yorumlar
  const comments = [
    {
      post_id: 1,
      comment: "Great post! Very informative.",
      author: "User123"
    },
    {
      post_id: 1,
      comment: "Thanks for sharing this information.",
      author: "TestUser"
    }
  ];

  comments.forEach(comment => {
    db.run("INSERT INTO comments (post_id, comment, author) VALUES (?, ?, ?)",
           [comment.post_id, comment.comment, comment.author]);
  });

  console.log("✅ Demo data created successfully!");
});

db.close();
