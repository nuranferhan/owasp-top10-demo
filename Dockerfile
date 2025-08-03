FROM node:16-alpine

WORKDIR /app

# Build araçlarını ekle (sqlite3 için gerekli)
RUN apk add --no-cache python3 make g++ sqlite

# Copy package files
COPY vulnerable-app/package*.json ./

# Container içinde dependencies yükle (Windows binary'leri yerine Linux binary'leri)
RUN npm install

# Vulnerable-app içeriğini kopyala (node_modules hariç)
COPY vulnerable-app/ ./

# Node_modules'ı korumak için tekrar yükle
RUN npm install --production

# Dizin yapısını ve izinleri ayarla
RUN mkdir -p public/uploads public/css public/js && \
    chmod -R 755 public/ && \
    touch database.db && \
    chmod 666 database.db

# Debug için dosya yapısını kontrol et
RUN echo "=== SQLite3 build kontrol ===" && \
    ls -la node_modules/sqlite3/build/Release/ && \
    echo "=== CSS dosyası kontrol ===" && \
    ls -la public/css/

# Expose port
EXPOSE 3000

# Start application
CMD ["node", "server.js"]