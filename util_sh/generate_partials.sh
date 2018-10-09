#!/bin/sh
ruby ./util_rb/generate_partial.rb 'partials/projects.html' 'apache/www/index_test.html' 'apache/www/index_prod.html' 'testsrv=[[hostname]] ' ' [[hostname]]=testsrv' 'prodsrv=[[hostname]] ' ' [[hostname]]=prodsrv' 'teststats.cncf.io,devstats.cncf.io' '[[hostname]]'
