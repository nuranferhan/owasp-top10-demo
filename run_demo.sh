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
