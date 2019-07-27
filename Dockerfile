FROM alpine:edge

RUN apk -U upgrade && apk add bash curl jq && rm -rf /var/cache/apk/*
ADD es-remove-duplicate.sh /
RUN chmod +x /es-remove-duplicate.sh
ENTRYPOINT /es-remove-duplicate.sh
