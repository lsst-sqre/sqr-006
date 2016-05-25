sub vcl_recv {
  # ...

  if( req.url ~ "/$" ) {
    set req.url = req.url "index.html";
  }

  # ...
}
