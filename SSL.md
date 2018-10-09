# Enable SSL/https Grafana (Ubuntu 17 using certbot)

To install Let's encrypt via certbot:

- First you need to install certbot, this is for example for Apache on Ubuntu 17.04:
- `sudo apt-get update`
- `sudo apt-get install software-properties-common`
- `sudo add-apt-repository ppa:certbot/certbot`
- `sudo apt-get update`
- `sudo apt-get install python-certbot-apache`
- `sudo certbot --apache`
- To install certificate for multiple domains use: `sudo certbot --apache -d 'domain1,domain2,..,domainN'`
- Choose to redirect all HTTP trafic to HTTPS.
- Then you need to proxy Apache https/SSL on port 443 to http on port 3000 (this is where Grafana listens)
- Your Grafana lives in https://your-domain.xyz (and https is served by Apache proxy to Grafana https:443 -> http:3000)
- In multiple hostnames used on single IP/Apache server, then you will redirect to different ports depending on current host name
- See `apache/prod/sites-available/000-default-le-ssl.conf` for details (teststats.cncf.io and prometheus.teststats.cncf.io configured there).
- Modified Apache config files are in [apache](https://github.com/cncf/devstats/blob/master/apache/), you need to check them and enable something similar on your machine.
- You can for instance put [database dump](https://devstats.cncf.io/gha.sql.xz) there (main domain is a static page, all projects live in subdomains).
- Files in [apache](https://github.com/cncf/devstats/blob/master/apache/) should be copied to `/etc/apache2` (see comments starting with `LG:`) and then `service apache2 restart`
- You can configure multiple domains for a single server:
- `sudo certbot --apache -d 'teststats.cncf.io,k8s.teststats.cncf.io,prometheus.teststats.cncf.io,opentracing.teststats.cncf.io,fluentd.teststats.cncf.io,linkerd.teststats.cncf.io,grpc.teststats.cncf.io,coredns.teststats.cncf.io,cncf.teststats.cncf.io'`
- Most up to date commands to request SSL cers are at the botom of [this](https://github.com/cncf/devstats/blob/master/ADDING_NEW_PROJECT.md) file.

# Automatic deploy
- All informations above are for manual deployment.
- This is all done as a part of `devel/deploy_all.sh`, `devel/create_www.sh`.
