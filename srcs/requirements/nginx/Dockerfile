FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx openssl && \
    rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

RUN mkdir -p /etc/nginx/ssl

RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=edidier.42.fr/" \
    -out /etc/nginx/ssl/nginx.crt \
    -keyout /etc/nginx/ssl/nginx.key

CMD ["nginx", "-g", "daemon off;"]
