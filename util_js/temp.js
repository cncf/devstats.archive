
  const puppeteer = require('puppeteer');
  (async () => {
    const browser = await puppeteer.launch({headless: true, args:['--no-sandbox']});
    const page = await browser.newPage();
    await page.goto('https://k8s.devstats.cncf.io/d/8/company-statistics-by-repository-group?orgId=1&var-period=w&var-metric=authors&var-repogroup_name=All&var-companies=All&from=1401580800000&to=1542788761000');
    await page.screenshot({path: '/var/www/html/img/projects/k8s-period-w-metric-authors.png'});
    await browser.close();
  })();
  