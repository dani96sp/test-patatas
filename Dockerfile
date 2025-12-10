# 1. IMAGEN BASE
FROM php:8.2-fpm-alpine

# 2. INSTALAR DEPENDENCIAS DEL SISTEMA
# build-base es virtual (.build-deps) para poder borrarlo después y mantener la imagen ligera
RUN apk update && apk add --no-cache \
    git \
    curl \
    nginx \
    libpq \
    && apk add --no-cache --virtual .build-deps \
    build-base \
    postgresql-dev \
    # 3. INSTALAR EXTENSIONES DE PHP
    && docker-php-ext-install pdo pdo_pgsql opcache exif \
    # Limpiar dependencias de compilación
    && apk del .build-deps \
    && rm -rf /var/cache/apk/*

# Crear directorio PID para Nginx (Crucial en Alpine)
RUN mkdir -p /run/nginx

# 4. INSTALAR COMPOSER
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# 5. CONFIGURACIÓN DEL SERVIDOR WEB
# Alpine usa http.d por defecto, asegúrate de que tu configuración sea compatible
COPY .docker/nginx/default.conf /etc/nginx/http.d/default.conf

# 6. CONFIGURACIÓN DEL PROYECTO
WORKDIR /var/www/html

# 7. OPTIMIZACIÓN DE CACHÉ (Primero dependencias, luego código)
# Copiamos solo los archivos de definición de dependencias
COPY composer.json composer.lock* ./

# 8. INSTALAR DEPENDENCIAS DE PHP
# Ejecutamos install. Si no hay dependencias, esto será rápido.
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction

# Ahora copiamos el resto del código
COPY . .

# 9. PERMISOS
RUN chown -R www-data:www-data /var/www/html

# 10. EXPONER PUERTOS
EXPOSE 80

# 11. COMANDO DE INICIO CORREGIDO
# Usamos php-fpm -D para enviarlo al fondo (daemon) y luego iniciamos Nginx
CMD sh -c "php-fpm -D && nginx -g 'daemon off;'"
