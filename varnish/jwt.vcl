sub vcl_init {
    new v = crypto.verifier(sha256, {"
-----BEGIN PUBLIC KEY-----
....INSERT YOUR PUBLIC KEY HERE......
-----END PUBLIC KEY-----
"});
}

sub jwt {
    if(req.http.Authorization && req.http.Authorization ~ "Bearer") {
        set req.http.x-token =  regsuball(req.http.Authorization, "Bearer ", "");

        set req.http.tmpHeader = regsub(req.http.x-token,"([^\.]+)\.[^\.]+\.[^\.]+","\1");
        set req.http.tmpTyp = regsub(digest.base64_decode(req.http.tmpHeader),{"^.*?"typ"\s*:\s*"(\w+)".*?$"},"\1");
        set req.http.tmpAlg = regsub(digest.base64_decode(req.http.tmpHeader),{"^.*?"alg"\s*:\s*"(\w+)".*?$"},"\1");


        if(req.http.tmpTyp != "JWT") {
            return(synth(401, "Invalid JWT Token: Token is not a JWT: " + req.http.tmpHeader));
        }
        if(req.http.tmpAlg != "RS256") {
            return(synth(401, "Invalid JWT Token: Token does not use HS256 hashing"));
        }

        set req.http.tmpPayload = regsub(req.http.x-token,"[^\.]+\.([^\.]+)\.[^\.]+$","\1");
        set req.http.tmpRequestSig = regsub(req.http.x-token,"^[^\.]+\.[^\.]+\.([^\.]+)$","\1");

        v.update(req.http.tmpHeader + "." + req.http.tmpPayload );


        if (! v.valid( blob.decode(BASE64URLNOPAD, encoded=req.http.tmpRequestSig))) {
            return (synth(401, "Invalid JWT Token: Signature"));
        }

        set req.http.X-Expiration = regsub(digest.base64_decode(req.http.tmpPayload), {"^.*?"exp":([0-9]+).*?$"},"\1");

        if (std.integer(req.http.X-Expiration, 0) <  std.time2integer(now, 0)) {
            return (synth(401, "Invalid JWT Token: Token expired"));
        }

        unset req.http.tmpHeader;
        unset req.http.tmpTyp;
        unset req.http.tmpAlg;
        unset req.http.tmpPayload;
        unset req.http.tmpRequestSig;
    }
}
