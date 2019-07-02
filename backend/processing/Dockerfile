
FROM node:8

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

EXPOSE 6379

CMD ["npm", "start"]

