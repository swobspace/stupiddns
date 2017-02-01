# stupiddns
A rubydns based DNS server which delivers always the same fixed ip address.

This server is intended to use in combination with a real dns server like bind and domain blacklists.
If a request is block by the domain blacklist, bind forwards the the request to stupiddns. stupiddns answers
with a fixed preconfigured ip address. Whitout a dns response record you won't get a log entry in most logfiles,
i.e. squid3 doesn't log the full client request if the dns query is unsuccessful.
