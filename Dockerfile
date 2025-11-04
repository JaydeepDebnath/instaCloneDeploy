#Stage 1: Build FLutter app
FROM ghcr.io/cirruslabs/flutter:3.27.4 AS build 
WORKDIR /app
COPY pubspec.* ./ 
RUN flutter pub get
COPY . .
RUN flutter config --enable-web 
RUN flutter build web --release

#Stage 2: Server using Nginx
FROM nginx:1.25-alpine3.17
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD [ "nginx","-g","daemon off;" ]