############################
# STEP 1 build executable binary
############################
FROM node:12-alpine as builder

ARG GIT_TOKEN
ENV NODE_ENV=production

# Install git + SSL ca certificates.
# Git is required for fetching the dependencies.
# Ca-certificates is required to call HTTPS endpoints.
RUN apk update && apk add --no-cache git ca-certificates tzdata && update-ca-certificates

# Create appuser
RUN adduser -D -g '' appuser

RUN mkdir -p /app
WORKDIR /app

# Install app dependencies
COPY package.json /app
COPY yarn.lock /app
# COPY .npmrc /app
RUN yarn

COPY . .

RUN yarn build

############################
# STEP 2 build a small image
############################
FROM node:12-alpine

RUN mkdir -p /app
WORKDIR /app

COPY --from=builder /app/build/server /app
COPY --from=builder /app/build/client /app/static

USER appuser

EXPOSE 8500
CMD [ "node", "server.js" ]