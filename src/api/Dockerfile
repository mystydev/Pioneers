
FROM node:8

WORKDIR /app
COPY api/package*.json ./
COPY api/certs/* certs/
RUN npm install
COPY api/* ./
COPY compute/* compute/

# Make port 80 available to the world outside this container
EXPOSE 443
EXPOSE 6379

CMD ["npm", "start"]

