FROM node:18-alpine

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci --only=production && \
    npm install -D nodemon

COPY . .

EXPOSE 3002

CMD ["npm", "run", "dev"]
