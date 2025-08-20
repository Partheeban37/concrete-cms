# Concrete CMS 9.4.3 - Dockerfile
# Base image: PHP 8.1 with Apache
FROM php:8.1-apache

# Set working directory
WORKDIR /var/www/html

# Install system dependencies & PHP extensions
RUN apt-get update && apt-get install -y \
    unzip \
    git \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    mariadb-client \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql gd mbstring zip xml \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache modules required by Concrete CMS
RUN a2enmod rewrite headers

# Copy source code from your GitHub repo (use local clone when building)
COPY . /var/www/html

# Install Composer (from official Composer image)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install PHP dependencies (optimize for production)
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Fix permissions for Apache/www-data
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \;

# Configure Apache for Concrete CMS pretty URLs
RUN echo "<Directory /var/www/html>\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>" > /etc/apache2/conf-available/concretecms.conf \
    && a2enconf concretecms

# Expose Apache port
EXPOSE 80

# Start Apache in foreground
CMD ["apache2-foreground"]
