# Minimal Dockerfile for WebSocket client
FROM node:14-alpine

WORKDIR /usr/src/app

# Install dependencies
COPY package.json package-lock.json* ./
RUN npm install --production

# Copy client code
COPY client.js ./

# Environment variables: ENDPOINT (ws://...), WAIT (seconds), CONNECTIONS

CMD ["npm", "start"]
