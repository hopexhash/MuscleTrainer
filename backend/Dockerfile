FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY server.js exercises.json ./
COPY public ./public
ENV PORT=4000 VIDEOS_DIR=/data/videos
EXPOSE 4000
CMD ["node", "server.js"]
