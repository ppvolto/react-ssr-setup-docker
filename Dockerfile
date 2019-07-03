FROM node:12-alpine as node_base

FROM node_base as deps
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

RUN apk update && apk add --no-cache git ca-certificates tzdata yarn && update-ca-certificates

WORKDIR /usr/app
COPY package.json /usr/app/package.json
COPY yarn.lock /usr/app/yarn.lock
#COPY .npmrc /usr/app/.npmrc
RUN yarn install --frozen-lockfile --production && yarn cache clean

FROM node_base as build

WORKDIR /usr/app
COPY package.json /usr/app/package.json
COPY yarn.lock /usr/app/yarn.lock
COPY .npmrc /usr/app/.npmrc
RUN yarn install --frozen-lockfile && yarn cache clean
COPY --from=deps /usr/app/node_modules /usr/app/node_modules
COPY . /usr/app
RUN yarn build

FROM node_base as release
WORKDIR /usr/app
COPY --from=build /usr/app/build/client /usr/app/client
COPY --from=build /usr/app/build/server /usr/app/server
COPY --from=deps /usr/app/node_modules /usr/app/node_modules

USER node

EXPOSE 8500
CMD [ "node", "server/server.js" ]

