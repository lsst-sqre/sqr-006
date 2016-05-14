if (resp.status == 900 ) {
  set resp.status = 301;
  set resp.response = "Moved Permanently";
}

if( req.url ~ "^/en/latest" && resp.status == 301 ) { 
  set resp.http.location = "https://" req.http.Fastly-Orig-Host regsub(req.url, "^/en/latest(.+)$", "\1");
}
