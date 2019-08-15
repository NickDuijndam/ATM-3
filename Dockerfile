FROM alpine:3.10

WORKDIR /github/workspace

RUN apk add curl wget bash jq zip python3

ENTRYPOINT ["bash", "./deploy.sh"]
