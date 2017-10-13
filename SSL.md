# Enable SSL/https Grafana (Ubuntu 17 using certbot)

To install Let's encrypt via certbot:

- First You need to install certbot, this is for example for Apache on Ubuntu 17.04:
- `sudo apt-get update`
- `sudo apt-get install software-properties-common`
- `sudo add-apt-repository ppa:certbot/certbot`
- `sudo apt-get update`
- `sudo apt-get install python-certbot-apache`
- `sudo certbot --apache`
- Choose to redirect all HTTP trafic to HTTPS.
- Then You need to proxy Apache https/SSL on port 443 to http on port 3000 (this is where Grafana listens)
- Your Grafana lives in https://your-domain.xyz (and https is served by Apache proxy to Grafana https:443 -> http:3000)
- Modified Apache config files are in [apache](https://github.com/cncf/gha2db/blob/master/apache/), You need to check them and enable something similar on Your machine.
- Please note that those modified Apache files additionally allows to put Your website in `/web` path (this path is in exception list and is not proxied to Grafana), so You can for instance put [database dump](https://devstats.k8s.io/web/k8s.sql.xz) there.
- Files in `[apache](https://github.com/cncf/gha2db/blob/master/apache/) should be copied to `/etc/apache2` (see comments starting with `LG:`) and then `service apache2 restart`
