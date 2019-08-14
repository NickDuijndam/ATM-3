FROM alpine:3.10

WORKDIR /github/workspace

RUN apk add curl wget bash jq tar

ENTRYPOINT ["bash", "./deploy.sh"]
