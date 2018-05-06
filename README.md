goals:

- replicate an static website for offline browsing
- respect / maintain original URLS 
- fast, but controlling max concurrency



idea 1:

- crawl site and download pages. Follow links.
- store them untouched locally in a folder structure following the site's paths ("/" -> subdirectory)
- browse locally by altering local hosts file
- open a simple webserver to serve static files under localhost




implementation:

- PageDownloader(url)
    * check input url is complete (host, domain, path, etc.)
        * abort if false
    * start locking by given url (in some global way)
    * check if given url has already been parsed
        * abort if true
    * open database transaction
    * fetch it
        * abort if permanent error (404, ...), but retry connection
    * get HTML
    * parse for other urls of the same domain.
    * store contents locally in some file, whatever
    * store in database this info
        - `url` -> `stored location`
    * write database to mark url as already parsed
    * commit transaction
    * free lock on url
    * Open `PageDownloader` for the parsed urls.
    
- `PageDownloader` are executed inside workers. there are N concurrent workers

- Worker lifecycle:
    * open new database connection
    * 