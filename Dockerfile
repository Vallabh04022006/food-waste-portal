
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
RUN printf 'server { listen 80; location / { return 503; } }\n' > /etc/nginx/conf.d/default.conf
EXPOSE 80
