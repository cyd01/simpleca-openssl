TARGET=simpleca

.PHONY: build run upx test

build:
	@docker build -f Dockerfile -t $(TARGET) .

run:
	@docker run --rm -it -p 8080:80 --name $(TARGET) $(TARGET) /bin/sh

basicweb: basicweb.go go.mod
	GOOS=linux GOARCH=386 go build

go.mod:
	@go mod init basicweb

upx: 
	@upx -9f basicweb

test:
	@rm www.localhost.com.key www.localhost.com.csr www.localhost.com.crt 2> /dev/null || test 1
	@openssl req -new -newkey rsa:2048 -nodes -keyout www.localhost.com.key -out www.localhost.com.csr -subj "/C=FR/ST=France/L=Paris/O=MyOrg/OU=MyUnit/CN=www.localhost.com"
	curl http://127.0.0.1:8080/ca/ca.crt -o ca.crt
	curl -v -X POST -H "Content-type: text/plain" 'http://127.0.0.1:8080/sign?name=www.localhost.com&days=100' --data-binary "@www.localhost.com.csr"
	curl -X POST -H "Content-type: text/plain" 'http://127.0.0.1:8080/sign?name=www.localhost.com&days=100' --data-binary "@www.localhost.com.csr" > www.localhost.com.crt

clean:
	@rm *.pem *.crt *.key *.csr 2> /dev/null || test 1
	@docker inspect $(TARGET) > /dev/null 2>&1 && docker kill $(TARGET) || test 1
	@docker rm -f $(TARGET) > /dev/null 2>&1 || test 1
	@docker image inspect $(TARGET) > /dev/null 2>&1 && docker rmi $(TARGET) || test 1
