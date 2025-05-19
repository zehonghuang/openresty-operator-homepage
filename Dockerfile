FROM nginx:alpine
COPY public/ /usr/share/nginx/html
RUN chmod -R a+r /usr/share/nginx/html