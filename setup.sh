#!/bin/bash

echo "🎯 OWASP Top 10 Demo Project Setup"
echo "=================================="

# Klasör yapısını oluştur
echo "📁 Creating project structure..."
mkdir -p owasp-top10-demo/{vulnerable-app/{public/{css,js,uploads},views,routes},exploits,docs}

# Ana dizine geç
cd owasp-top10-demo

# Vulnerable app setup
echo "🔧 Setting up vulnerable application..."
cd vulnerable-app

# package.json oluştur
cat > package.json << 'EOF'
{
  "name": "owasp-top10-demo",
  "version": "1.0.0",
  "description": "OWASP Top 10 Vulnerability Demonstration",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "sqlite3": "^5.1.6",
    "multer": "^1.4.5-lts.1",
    "bcrypt": "^5.1.0",
    "jsonwebtoken": "^9.0.0",
    "cookie-parser": "^1.4.6",
    "express-session": "^1.17.3",
    "body-parser": "^1.20.2",
    "ejs": "^3.1.9"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  }
}
EOF

# uploads klasörü oluştur
mkdir -p public/uploads
mkdir -p views

# CSS klasörüne stil dosyası oluştur
mkdir -p public/css

echo "📦 Installing Node.js dependencies..."
npm install

echo "🐍 Setting up Python exploit environment..."
cd ../exploits

# Python requirements dosyası oluştur
cat > requirements.txt << 'EOF'
requests>=2.28.0
urllib3>=1.26.0
beautifulsoup4>=4.11.0
lxml>=4.6.0
python-nmap>=0.7.0
colorama>=0.4.0
EOF

echo "📦 Installing Python dependencies..."
pip3 install -r requirements.txt

cd ..

# Demo data scripti oluştur
cat > create_demo_data.js << 'EOF'
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
EOF

# Çalıştırma scripti oluştur
cat > run_demo.sh << 'EOF'
#!/bin/bash

echo "🚀 Starting OWASP Top 10 Demo Application"
echo "======================================="

# Terminal 1: Vulnerable app başlat
echo "🌐 Starting vulnerable application on http://localhost:3000"
echo "Press Ctrl+C to stop the application"
echo ""

cd vulnerable-app

# Demo data oluştur (sadece ilk çalıştırmada)
if [ ! -f "database.db" ]; then
    echo "📊 Creating demo data..."
    node ../create_demo_data.js
fi

# Uygulamayı başlat
npm start
EOF

# Test scripti oluştur
cat > run_tests.sh << 'EOF'
#!/bin/bash

echo "🔍 Running OWASP Top 10 Vulnerability Tests"
echo "==========================================="

TARGET_URL="http://localhost:3000"

# Uygulama çalışıyor mu kontrol et
echo "🔄 Checking if application is running..."
if ! curl -s "$TARGET_URL" > /dev/null; then
    echo "❌ Application is not running on $TARGET_URL"
    echo "Please start the application first with: ./run_demo.sh"
    exit 1
fi

echo "✅ Application is running"
echo ""

cd exploits

echo "🚀 Starting comprehensive vulnerability scan..."
python3 comprehensive_exploit.py "$TARGET_URL"

echo ""
echo "🔍 Running individual exploit tests..."

echo "1️⃣ Testing SQL Injection..."
python3 sql_injection.py "$TARGET_URL"

echo ""
echo "2️⃣ Testing XSS Vulnerabilities..."
python3 xss_exploit.py "$TARGET_URL"

echo ""
echo "3️⃣ Testing File Upload Vulnerabilities..."
python3 file_upload_exploit.py "$TARGET_URL"

echo ""
echo "4️⃣ CSRF exploit available at: exploits/csrf_exploit.html"
echo "   Open this file in browser after logging into the application"

echo ""
echo "✅ All tests completed!"
echo "📋 Check generated reports for detailed results"
EOF

# Scriptleri executable yap
chmod +x run_demo.sh
chmod +x run_tests.sh

# Docker setup (opsiyonel)
cat > Dockerfile << 'EOF'
FROM node:16-alpine

WORKDIR /app

# Copy package files
COPY vulnerable-app/package*.json ./vulnerable-app/
RUN cd vulnerable-app && npm install

# Copy application files
COPY . .

# Create uploads directory
RUN mkdir -p vulnerable-app/public/uploads

# Expose port
EXPOSE 3000

# Start application
CMD ["node", "vulnerable-app/server.js"]
EOF

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  vulnerable-app:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - ./vulnerable-app/database.db:/app/vulnerable-app/database.db
      - ./vulnerable-app/public/uploads:/app/vulnerable-app/public/uploads
    environment:
      - NODE_ENV=development
    
  exploit-runner:
    image: python:3.9-alpine
    depends_on:
      - vulnerable-app
    volumes:
      - ./exploits:/app/exploits
    working_dir: /app/exploits
    command: sh -c "pip install requests && python comprehensive_exploit.py http://vulnerable-app:3000"
EOF

# Git setup
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
*.log

# Database
*.db
*.sqlite

# Uploads
public/uploads/*
!public/uploads/.gitkeep

# Reports
vulnerability_report_*.json
*.txt

# Environment
.env
.env.local

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
EOF

# gitkeep dosyası oluştur
touch vulnerable-app/public/uploads/.gitkeep

echo ""
echo "✅ Setup completed successfully!"
echo ""
echo "🚀 To start the demo:"
echo "   1. ./run_demo.sh     # Start vulnerable application"
echo "   2. ./run_tests.sh    # Run vulnerability tests (in another terminal)"
echo ""
echo "🌐 Application will be available at: http://localhost:3000"
echo ""
echo "📋 Demo credentials:"
echo "   Admin: admin / admin123"
echo "   User:  user / user123"
echo ""
echo "🔍 Test URLs:"
echo "   • Main app: http://localhost:3000"
echo "   • Upload:   http://localhost:3000/upload.html"
echo "   • Admin:    http://localhost:3000/admin"
echo "   • XML test: http://localhost:3000/xml"
echo ""
echo "⚠️  SECURITY WARNING:"
echo "   This application contains intentional vulnerabilities!"
echo "   Only use in isolated test environments!"
echo ""
echo "🐳 Docker alternative:"
echo "   docker-compose up    # Start with Docker"
echo ""