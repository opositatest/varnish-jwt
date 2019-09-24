vcl 4.0;

import std;
import digest;
import crypto;
import blob;


sub vcl_init {
  new v = crypto.verifier(sha256, std.getenv("PUBLIC_KEY"));
}


backend default {
  .host = "nginx";
}


sub vcl_recv {
  # Remove the "Forwarded" HTTP header if exists (security)
  unset req.http.forwarded;

  if (req.http.cache-control ~ "(no-cache|private)" ||
      req.http.pragma ~ "no-cache") {
         return (pass);
  }

  if (req.method != "GET" && req.method != "HEAD") {
    return (pass);
  }

  if(req.http.Authorization && req.http.Authorization ~ "Bearer") {
      set req.http.x-token =  regsuball(req.http.Authorization, "Bearer ", "");

      set req.http.tmpHeader = regsub(req.http.x-token,"([^\.]+)\.[^\.]+\.[^\.]+","\1");
      set req.http.tmpTyp = regsub(digest.base64_decode(req.http.tmpHeader),{"^.*?"typ"\s*:\s*"(\w+)".*?$"},"\1");
      set req.http.tmpAlg = regsub(digest.base64_decode(req.http.tmpHeader),{"^.*?"alg"\s*:\s*"(\w+)".*?$"},"\1");


      if(req.http.tmpTyp != "JWT") {
          return(synth(401, "Invalid JWT Token: Token is not a JWT: " + req.http.tmpHeader));
      }
      if(req.http.tmpAlg != "RS256") {
          return(synth(401, "Invalid JWT Token: Token does not use RS256 hashing"));
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

      return (hash);
  }
}

sub vcl_hit {
    if (obj.ttl >= 0s) {
        // A pure unadultered hit, deliver it
        return (deliver);
    }
    if (obj.ttl + obj.grace > 0s) {
        // Object is in grace, deliver it
        // Automatically triggers a background fetch
        return (deliver);
    }

    return (pass);
}


sub vcl_deliver {
  # Don't send cache tags related headers to the client
  unset resp.http.url;
  # Comment the following line to send the "Cache-Tags" header to the client (e.g. to use CloudFlare cache tags)
  unset resp.http.Cache-Tags;

  if (obj.hits > 0) {
          set resp.http.X-Cache = "HIT";
  } else {
          set resp.http.X-Cache = "MISS";
  }
}

sub vcl_backend_response {
  # Ban lurker friendly header
  set beresp.http.url = bereq.url;

  # Add a grace in case the backend is down
  set beresp.grace = 1h;
}


sub vcl_synth {
    set resp.http.Content-Type = "application/json";
    synthetic( {"{ "code":"} + resp.status + {" "message": ""} + resp.reason + {"" }"} );

    return (deliver);
}
