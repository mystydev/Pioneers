
FROM node:12

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

EXPOSE 6420

ARG TYPE
ENV CTYPE=$TYPE

RUN if [ $CTYPE = "master" ] ; then cp master.js index.js ; fi
RUN if [ $CTYPE = "node" ] ; then cp node.js index.js ; fi
CMD ["node", "index.js"]

