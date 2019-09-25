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
  - Improve documentation
  - Improve test

Varnish
---

This image use this modules:

https://github.com/varnish/libvmod-digest.git  (Base64 utils)

https://code.uplex.de/uplex-varnish/libvmod-crypto (RSA algorytm)


Usage with docker-compose
---

Modify docke-compose.yml file

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
