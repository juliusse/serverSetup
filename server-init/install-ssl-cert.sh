#!/bin/sh
mv /etc/ssl/certs/server.crt /etc/ssl/certs/server.crt.dummy
mv ./my-docear-staging.pem /etc/ssl/certs/server.crt

mv /etc/ssl/private/server.key /etc/ssl/private/server.key.dummy
mv ./my-docear-staging.key /etc/ssl/private/server.key

service apache2 reload