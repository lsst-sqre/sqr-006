sub vcl_recv {

  # ...

  set req.http.Fastly-Orig-Host = req.http.host;
  set req.http.host = "bucket.s3.amazonaws.com";

  # ... HTTP -> HTTPS redirect code

  # ... Read the Docs redirection code

  # Rewrite URL for default edition (root URL)
  if( req.url !~ "^/v/|^/builds/" ) {
        set req.url = regsub(req.http.Fastly-Orig-Host,
                             "^(.+)\.lsst\.io$",
                             "/\1/v/main") req.url;
  }

  # Rewrite URL for editions and builds
  if( req.url ~ "^/v/" || req.url ~ "^/builds/" ) {
        set req.url = regsub(req.http.Fastly-Orig-Host,
                             "^(.+)\.lsst\.io$",
                             "/\1") req.url;
  }

  # ...

  return(lookup);
}
