#Stage 1: Build FLutter app
FROM ghcr.io/cirruslabs/flutter:3.27.3 AS build 
WORKDIR /app
COPY pubspec.* ./ 
RUN flutter pub get
COPY . .

# Ensure the "web" folder exists with a valid index.html
RUN mkdir -p web && \
    echo '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Flutter Web</title><base href="/"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head><body><script src="main.dart.js"></script></body></html>' > web/index.html

# Enable web support and fix root warning
RUN flutter config --enable-web
ENV CI=true

# Build Flutter web release
RUN flutter build web --release

#Stage 2: Server using Nginx
FROM nginx:1.25-alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD [ "nginx","-g","daemon off;" ]