
FROM node:8

WORKDIR /app
COPY package*.json ./
COPY certs/* certs/
RUN npm install
COPY . .

# Make port 80 available to the world outside this container
EXPOSE 443
EXPOSE 6379

CMD ["npm", "start"]

