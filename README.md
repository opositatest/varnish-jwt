[![CircleCI](https://circleci.com/gh/opositatest/varnish-jwt.svg?style=svg)](https://circleci.com/gh/opositatest/varnish-jwt)


This code is based in https://feryn.eu/blog/validating-json-web-tokens-in-varnish/

This code provides asymectric jwt validation RS256 instead symmetric HS256  

*Features:*

 - JWT Validation Signature
 - JWT Validation expiration
 - HIT/MISS Header
 - Use Authorization Bearer header

*Todo*
  - Allow multiple jwt validation algorithms
  - Improve test

Varnish
---

This image use this modules:

https://github.com/varnish/libvmod-digest.git  (Base64 utils)

https://code.uplex.de/uplex-varnish/libvmod-crypto (RSA algorytm)


Usage with docker-compose
---

Modify docker-compose.yml file

```
version: '3.7'
services:
  varnish:
    image: opositatest/varnish:latest
    links:
        - nginx:nginx
    ports:
        - 80:80
    environment:
        PUBLIC_KEY: |-
            -----BEGIN PUBLIC KEY-----
            ...ADD YOUR PUBLIC KEY...
            -----END PUBLIC KEY-----
```

Update default.vcl and add your custom host

```
backend default {
  .host = "nginx";
}
```


Notes
---

This code requires Authorization bearer:

```
curl -v -H "Authorization: Bearer AWESOME_TOKEN" -X GET "http://localhost:80/api/v1/some_resource" -H  "accept: application/json"
```


Test
---

```
docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```
The test files are in folder ```varnish/test/```:
* autorization.vtc

    This test verifies that Varnish is capable of working with JWT. Different content in the token is sent in each test and it is checked if the answer is the expected one.
* single_request.vtc

    This test makes a request emulating a client to check if the backend responds. 

If you want test that the Varnish service it is who listen to the request and respond to the request you have verify the response headers and looking for **X-Cache**:
* X-Cache is **HIT**: This request was attended by the Varnish server and this object existing on cache.
* X-Cache is **MISS**: This request was attend by Varnish but is not in cache and Varnish asked the backend for it request.
* X-Cache is not set: This request not was attend by Varnish server.

Example with a curl client:
```
# Request
curl -I localhost:80

# Response
HTTP/1.1 200 OK
Server: nginx/1.17.9
Date: Thu, 26 Mar 2020 14:27:45 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 03 Mar 2020 14:32:47 GMT
ETag: "5e5e6a8f-264"
X-Varnish: 7 3
Age: 8
Via: 1.1 varnish (Varnish/6.4)
X-Cache: HIT
Accept-Ranges: bytes
Connection: keep-alive
```