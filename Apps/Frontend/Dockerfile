# Stage 1: Build static assets
FROM node:24-alpine AS builder

WORKDIR /app

# Install pnpm version matching the workspace configuration
RUN npm install -g pnpm@10.33.0

# Copy package files for caching
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy the rest of the application files
COPY . .

# Set dynamic build arguments for public api base url
ARG NUXT_PUBLIC_API_BASE=/api
ENV NUXT_PUBLIC_API_BASE=$NUXT_PUBLIC_API_BASE

# Generate static Nuxt site
RUN pnpm run generate

# Stage 2: Serve static files with Nginx
FROM nginx:alpine

# Copy static output from build stage
COPY --from=builder /app/.output/public /usr/share/nginx/html

# Replace default Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose HTTP port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
