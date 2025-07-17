# Minimal Dockerfile for WebSocket server
FROM node:14-alpine

WORKDIR /usr/src/app

# Install dependencies
COPY package.json package-lock.json* ./
RUN npm install --production

# Copy application code
COPY server.js ./

# Expose WebSocket port
env PORT=8080
EXPOSE 8080

# Start the server
CMD ["npm", "start"]
