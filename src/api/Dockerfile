
FROM node:12

WORKDIR /app
COPY api/package*.json ./
COPY api/certs/* certs/
RUN npm install
COPY api/* ./
COPY compute/* compute/

EXPOSE 443
EXPOSE 6379

CMD ["npm", "start"]

