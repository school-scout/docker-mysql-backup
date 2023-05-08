FROM alpine:3.17.2

RUN apk add --no-cache bash gpg gpg-agent mysql-client rclone \
  && mkdir -p /root/.config/rclone \
  && touch /root/.config/rclone/rclone.conf

COPY entrypoint.sh /
CMD /entrypoint.sh
