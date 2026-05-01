FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN set -e && npm install --verbose
COPY . .
RUN set -e && npm run build --verbose
RUN set -e && \
    echo "Verifying dist output..." && \
    if [ ! -d "/app/dist" ] || [ -z "$(ls -A /app/dist)" ]; then \
        echo "ERROR: dist folder is missing or empty after build" >&2; \
        exit 1; \
    fi && \
    echo "dist folder OK — contents:" && \
    ls -lh /app/dist

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
