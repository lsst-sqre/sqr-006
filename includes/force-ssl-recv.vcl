if( !req.http.Fastly-SSL ) {
    set req.http.host = req.http.Fastly-Orig-Host;
}

if( req.url ) {
  if (!req.http.Fastly-SSL) {
     error 801 "Force SSL";
  }
  
  # ...
}
