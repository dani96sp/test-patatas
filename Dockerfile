# 1. IMAGEN BASE
# Usamos la imagen oficial de PHP con Alpine Linux (ligera) y FPM (FastCGI)
FROM php:8.2-fpm-alpine

# 2. INSTALAR DEPENDENCIAS DEL SISTEMA
# Instalamos Git, extensiones de PHP, Composer y herramientas de Postgres
RUN apk update && apk add --no-cache \
    git \
    build-base \
    # Herramientas para Composer y depuración
    curl \
    # Dependencias de PostgreSQL para PDO
    postgresql-dev \
    # Necesario para el servidor web (Nginx o Apache)
    nginx \
    # Limpiar
    && rm -rf /var/cache/apk/*

# 3. INSTALAR EXTENSIONES DE PHP
# Instalamos las extensiones PHP clave, incluyendo pdo_pgsql para PostgreSQL
RUN docker-php-ext-install pdo pdo_pgsql \
    # Extensiones útiles comunes
    opcache \
    mysqli \
    exif

# 4. INSTALAR COMPOSER
# Descargamos e instalamos Composer globalmente
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# 5. CONFIGURACIÓN DEL SERVIDOR WEB (Nginx)
# Copiamos la configuración básica de Nginx para PHP-FPM
COPY .docker/nginx/default.conf /etc/nginx/conf.d/default.conf

# 6. CONFIGURACIÓN DEL PROYECTO
# Definimos el directorio de trabajo (donde estará el código)
WORKDIR /var/www/html

# 7. COPIAR CÓDIGO Y DEPENDENCIAS
# Copiamos el código de la aplicación
COPY . /var/www/html

# 8. INSTALAR DEPENDENCIAS DE PHP
# Ejecutamos Composer para instalar las dependencias (si tienes un framework)
# Si no tienes un composer.json complejo, puedes comentar esta línea por ahora
RUN composer install --no-dev --optimize-autoloader

# 9. PERMISOS (Importante para evitar errores en producción/logs)
# Aseguramos que el usuario www-data tenga permisos sobre el código
RUN chown -R www-data:www-data /var/www/html

# 10. EXPONER PUERTOS (Nginx)
EXPOSE 80

# 11. COMANDO DE INICIO
# Este comando inicia FPM y Nginx en paralelo.
CMD sh -c "php-fpm && nginx -g 'daemon off;'"