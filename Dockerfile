#Stage 1: Build FLutter app
FROM ghcr.io/cirruslabs/flutter:3.22.0 AS build 
WORKDIR /app
COPY . .
RUN flutter build web --release

#Stage 2: Server using Nginx
FROM nginx:1.25-alpine3.17
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD [ "nginx","-g","deamon off;" ]