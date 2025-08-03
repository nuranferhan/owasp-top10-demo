# OWASP Top 10 Vulnerable Web Application

This project is a vulnerable web application designed to demonstrate the OWASP Top 10 security vulnerabilities.

---

## 🚀 Getting Started

### Requirements

- Docker  
- Docker Compose

### Quick Start

```bash
# Start the containers
docker-compose up

# Run in the background
docker-compose up -d
````

---

## 🛠️ If Running for the First Time or Facing Issues

```bash
# For Windows users: prevent node_modules conflicts
rmdir /s /q vulnerable-app\node_modules

# Clean containers and rebuild
docker-compose down
docker-compose build --no-cache
docker-compose up
```

---

## Application URLs

* Main App: [http://localhost:3000](http://localhost:3000)
* Admin Panel: [http://localhost:3000/admin](http://localhost:3000/admin)
* Login: [http://localhost:3000/login](http://localhost:3000/login)

---

## Default Users

* Admin: `admin` / `admin123` (or the password in `.env`)
* User: `user` / `user123`

---

## Stopping Containers

```bash
# Stop the containers
docker-compose down

# Remove containers and volumes
docker-compose down -v

# Clean all Docker cache
docker system prune -f
```

---

## Troubleshooting

### SQLite3 "Exec format error"

```bash
# Remove Windows node_modules
rmdir /s /q vulnerable-app\node_modules

# Rebuild
docker-compose build --no-cache
docker-compose up
```

### CSS Not Loading?

* Check if the CSS file exists inside the container:

  ```bash
  docker exec -it owasp-top10-demo-vulnerable-app-1 ls -la /app/public/css/
  ```
* Test the CSS link directly in the browser:
  [http://localhost:3000/css/style.css](http://localhost:3000/css/style.css)

---

## Viewing Container Logs

```bash
# View all logs
docker-compose logs

# Only vulnerable-app logs
docker-compose logs vulnerable-app

# Live log tailing
docker-compose logs -f vulnerable-app
```

---

## Accessing the Container

```bash
# Enter the container shell
docker exec -it owasp-top10-demo-vulnerable-app-1 sh

# Exit the container
exit
```

---

## Security Warning

This application is INTENTIONALLY VULNERABLE! Use only for educational purposes and NEVER in production environments.

---

## Vulnerabilities Detected by Exploit Scripts

When you run the exploit scripts, the following vulnerabilities are demonstrated:

* SQL Injection
* Cross-Site Scripting (XSS)
* File Upload Vulnerabilities
* XML External Entities (XXE)
* Missing Security Headers
* Information Disclosure
* And more...

> **Risk Score: 160/100 (CRITICAL)**

---

## Exploit Scripts

Python scripts are located inside the `exploit/` folder and can be used to test vulnerabilities manually.

### How to Use

```bash
# Go to the exploit folder
cd exploit

# Example: Run the SQL Injection test
python3 exploit_sqli.py

# Run other scripts similarly
python3 exploit_xss.py
python3 exploit_file_upload.py
python3 exploit_xxe.py
...
```

> These scripts do **NOT** run automatically during setup. You must run them manually after the app is running.

```

