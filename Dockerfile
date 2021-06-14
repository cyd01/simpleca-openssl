FROM golang as buildbinary
RUN mkdir /go/src/basicweb
COPY basicweb.go /go/src/basicweb/basicweb.go
RUN cd /go/src/basicweb && go mod init basicweb && go get && GOOS=linux GOARCH=386 go build

FROM alpine as buildimage
RUN mkdir -p /data /data/scripts
RUN apk add --update openssl
COPY --from=buildbinary /go/src/basicweb/basicweb /usr/local/bin/basicweb
COPY entrypoint.sh /entrypoint.sh
COPY sign.sh /data/scripts/sign.sh
RUN chmod +x /usr/local/bin/basicweb entrypoint.sh /data/scripts/*.sh

FROM buildimage
COPY --from=buildimage / /

EXPOSE 80
WORKDIR /data
ENTRYPOINT [ "/entrypoint.sh" ]
