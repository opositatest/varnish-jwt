vcl 4.0;

import std;
import digest;
import crypto;
import blob;


include "jwt.vcl";

backend default {
  .host = "nginx";
}


sub vcl_recv {
  if (req.restarts > 0) {
    set req.hash_always_miss = true;
  }

  # Remove the "Forwarded" HTTP header if exists (security)
  unset req.http.forwarded;

  # For health checks
  if (req.method == "GET" && req.url == "/healthz") {
    return (synth(200, "OK"));
  }

  if (req.http.cache-control ~ "(no-cache|private)" ||
      req.http.pragma ~ "no-cache") {
         return (pipe);
  }

  call jwt;

  return (hash);
}

sub vcl_hit {
  if (obj.ttl >= 0s) {
    # A pure unadulterated hit, deliver it
    return (deliver);
  }

  if (std.healthy(req.backend_hint)) {
    # The backend is healthy
    # Fetch the object from the backend
    return (restart);
  }

  # No fresh object and the backend is not healthy
  if (obj.ttl + obj.grace > 0s) {
    # Deliver graced object
    # Automatically triggers a background fetch
    return (deliver);
  }

  # No valid object to deliver
  # No healthy backend to handle request
  # Return error
  return (synth(503, "API is down"));
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
    set resp.http.Retry-After = "5";
    synthetic( {"{ "code":"} + resp.status + {" "message": ""} + resp.reason + {"" }"} );

    return (deliver);
}
