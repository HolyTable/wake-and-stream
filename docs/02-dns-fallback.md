# 2 – DNS fallback (optional)

Only relevant if a **Pi-hole** (or other DNS filter) on your NAS is the DNS server for your network.
If the NAS restarts or the container stops, every device loses name resolution – including the Mac in
the VPN. A fallback keeps the internet working (just without ad blocking for that time).

Recommended chain:

```
devices ──► router (local DNS) ──► Pi-hole (preferred)
                               └─► public DNS, e.g. 1.1.1.1 (alternative)
```

FRITZ!Box example:

1. *Internet → Account Information → DNS Server* → use other DNSv4 servers:
   preferred = your Pi-hole IP (e.g. `192.168.1.10`), alternative = `1.1.1.1`.
2. *Home Network → Network → Network Settings → IPv4* → **local DNS server = the router itself**
   (remove the Pi-hole IP there, otherwise devices bypass the fallback).
3. In Pi-hole make sure the **upstream** DNS servers are public ones – never the router (that would
   create a loop).

**Test:** stop the Pi-hole container → websites still load → start it again.

> Side effect: Pi-hole's statistics now show most queries as coming from the router.
