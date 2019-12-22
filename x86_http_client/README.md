# x86 HTTP Client

In order to practice learning x86 assembly I decided to make a HTTP client. This will work _like_ curl.

## Building

This is just a make file so run:

```
$ make
```

## Version 0.1

How this will work is that it will take a two arguments the domain name and the port number (default to 80). It will then return the html of the home webpage.

```
$ ./http_client www.example.com 80
<!DOCTYPE HTML>
<html>
    <head>
...
```