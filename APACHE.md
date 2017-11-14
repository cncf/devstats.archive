# Apache installation

- Install apache: `apt-get install apache2`
- Create "web" directory: `mkdir /var/www/html/` (it will hold gha databases dumps and other static info on the main domain.)
- Copy `apache/www/index.html` to `/var/www/html` and adjust this file if needed.
- Enable mod proxy: `ln /etc/apache2/mods-available/proxy.load /etc/apache2/mods-enabled/`
- `ln /etc/apache2/mods-available/proxy.conf /etc/apache2/mods-enabled/`
- `ln /etc/apache2/mods-available/proxy_http.load /etc/apache2/mods-enabled/`
- `ln /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/`
- You can enable SSL, to do so You need to follow SSL instruction in [SSL](https://github.com/cncf/devstats/blob/master/SSL.md) (that requires domain name).
- `service apache2 restart`
