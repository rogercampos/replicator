# Replicator

Store a copy of an static website locally for offline browsing. Requires a working ruby interpreter >= 2.3.

Use this to start a crawling, pass website's root path and a local dir to store the copy.

```
> ./store http://mysite.com ~/sites
```

This will create the directory `~/sites/mysite.com` which will contain all the scraped data.

Then, you can browse locally by starting a local webrick webserver.

```
> ./server ~/sites/mysite.com
```

Point your browser to `http://localhost:8080`. 

- The crawling will follow any link of the same domain as the initial url given. But no others.

- All the domain will be crawled, there's no support for filtering.

- By default the crawler will use 3 concurrent workers, meaning the domain will be hit as much as 3 times concurrently.
You can adjust this setting passing a positive integer as the second argument:

    `./store http://mysite.com ~/sites 10`
    
    Just be responsible and don't flood websites that may not have enough capacity to support it.
    
- If you stop a crawler with ctrl-c (or SIGINT), the program will gracefully shutdown and store its temporal state. 
The next time you start again a crawling on the same domain, the work will be resumed. No time will be lost.

- If the program experiences an unexpected error (or it's killed non-gracefully), no temporal state will be saved but 
all the crawled data up to that point will still be saved. The next time you start again a crawling on the same domain,
the work will begin from the start again. However, the program will know about the pages it previously crawled and
skip them, gaining time. It will only need to parse them again to extract urls to follow because it doesn't know
at what point it will find the next uncrawled page.
