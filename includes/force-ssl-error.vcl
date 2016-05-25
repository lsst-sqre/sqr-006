if (obj.status == 801) {
   set obj.status = 301;
   set obj.response = "Moved Permanently";
   set obj.http.Location = "https://" req.http.host req.url;
   synthetic {""};
   return (deliver);
}
