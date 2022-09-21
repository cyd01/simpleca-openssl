# SimpleCA

How to make a very simple Certificate Authority.

SimpleCA is simply based on [OpenSSL](https://www.openssl.org/).  
SimpleCA also expose a Web API in a very light Golang Web server.  
To use this API it is only necessary to send a Certificate request (CSR) in the body of a POST request, to receive the signed certificate (CRT) in the body of the response.  
SimpleCA is available in a Docker image (see [Dockerfile](Dockerfile)).

## How to build

The Dockerfile is used
- to compile Golang Web server
- build the image
- shrink this image in a final one-layer image

The build command is

    docker build -f Dockerfile -t simpleca .

## How to run

The data (AC definition and CSR+CRT requests) need not be saved from an execution to another.  
In order to do it the first thing to create is a Docker volume.  

    docker volume create simpleca_data

Then the startup command is 

    docker run --rm -d -p 8080:80 -v simpleca_data:/data --name simpleca simpleca

> In this context, the service is accessible on port `8080`.

To stop the service

    docker stop simpleca

The iternal AC can be configured by passing some environment variables to the **run** command with the `-e` parameter.

| Parameter             | Descritpion                                                   | Default value |
| --------------------- | ------------------------------------------------------------- | ------------- |
| SIMPLECA_KEYSIZE      | The size of the AC private key                                | 2048          |
| SIMPLECA_PASSWORD     | The password of the AC private key                            | -             |
| SIMPLECA_EXPIRATION   | The number of days before expiration of genrated certificates | 3650          |
| SIMPLECA_DEFAULTMD    | default signature algorithm                                   | sha256        |
| SIMPLECA_COUNTRYNAME  | Country name                                                  | FR            |
| SIMPLECA_STATE        | State                                                         | France        |
| SIMPLECA_LOCALITY     | Locality                                                      | Paris         |
| SIMPLECA_ORGANIZATION | Organization                                                  | MyOrg         |
| SIMPLECA_UNIT         | Organization unit                                             | MyUnit        |

## How to use it

The certificate of the internal AC is available at `/ca/ca.crt`.  
Here a simple `curl` syntax to download it in a `ca.crt` file.

    curl -kL http://127.0.0.1:8080/ca/ca.crt -o ca.crt

Assuming we already have generated a CSR for `www.localhost.com` domain in `domain.csr` file.  
The right syntax to get the corresponding certificate is:  

    curl -X POST -H "Content-type: text/plain" 'http://127.0.0.1:8080/sign?name=www.localhost.com&days=100' --data-binary "@domain.csr" -o domain.crt

