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
echo "3️⃣ Testing Brute Force Authentication Vulnerabilities..."
python3 brute_force_auth.py "$TARGET_URL"

echo ""
echo "3️⃣ Testing Sensitive Data Exposure Vulnerabilities..."
python3 sensitive_data_exposure.py "$TARGET_URL"

echo ""
echo "3️⃣ Testing XXE Exploit Vulnerabilities..."
python3 xxe_exploit.py "$TARGET_URL"

echo ""
echo "4️⃣ CSRF exploit available at: exploits/csrf_exploit.html"
echo "   Open this file in browser after logging into the application"

echo ""
echo "✅ All tests completed!"
echo "📋 Check generated reports for detailed results"
