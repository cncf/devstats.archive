# Enable SSL/https Grafana (Ubuntu 17 using certbot)

To install Let's encrypt via certbot:

- First You need to install certbot, this is for example for Apache on Ubuntu 17.04:
- `sudo apt-get update`
- `sudo apt-get install software-properties-common`
- `sudo add-apt-repository ppa:certbot/certbot`
- `sudo apt-get update`
- `sudo apt-get install python-certbot-apache`
- `sudo certbot --apache`
- To install certificate for multiple domains use: `sudo certbot --apache -d 'domain1,domain2,..,domainN'`
- Choose to redirect all HTTP trafic to HTTPS.
- Then You need to proxy Apache https/SSL on port 443 to http on port 3000 (this is where Grafana listens)
- Your Grafana lives in https://your-domain.xyz (and https is served by Apache proxy to Grafana https:443 -> http:3000)
- In multiple hostnames used on single IP/Apache server, then You will redirect to different ports depending on current host name
- See `apache/sites-available/000-default-le-ssl.conf` for details (cncftest.io and prometheus.cncftest.io configured there).
- Modified Apache config files are in [apache](https://github.com/cncf/devstats/blob/master/apache/), You need to check them and enable something similar on Your machine.
- You can for instance put [database dump](https://devstats.k8s.io/gha.sql.xz) there (main domain is a static page, all projects live in subdomains).
- Files in `[apache](https://github.com/cncf/devstats/blob/master/apache/) should be copied to `/etc/apache2` (see comments starting with `LG:`) and then `service apache2 restart`
- You can configure multiple domains for a single server:
- `sudo certbot --apache -d cncftest.io,k8s.cncftest.io,prometheus.cncftest.io,opentracing.cncftest.io`
