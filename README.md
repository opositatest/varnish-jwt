
This code is based in https://feryn.eu/blog/validating-json-web-tokens-in-varnish/

This code provides asymectric jwt validation RS256 instead symmetric HS256  

Features:

 - JWT Validation Signature
 - JWT Validation expiration
 - HIT/MISS Header

TODO:

 - Testing
 - Parametrice KEYS and algorytm with environment variables


Varnish
---

This image use this modules:

https://github.com/varnish/libvmod-digest.git  (Base64 utils)

https://code.uplex.de/uplex-varnish/libvmod-crypto (RSA algorytm)


Install
---

Modify your jwt.vcl and add your public key.

```
new v = crypto.verifier(sha256, {"
-----BEGIN PUBLIC KEY-----
....INSERT YOUR PUBLIC KEY HERE......
-----END PUBLIC KEY-----
"});
´´´
