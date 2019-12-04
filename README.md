docker_mattermost 
=====================
docker-compose definition for deployment of naturalis mattermost server.


Docker-compose
--------------

This puppet script configures a complete docker-compose setup for mattermost. Which
consists of:

 - db
 - app
 - web
 - traefik 2.x

It is started using Foreman which creates:

 - .env file
 - traefik/traefik.toml

The puppet script generates:

-

Result
------
Working webserver with mysql and nextcloud installation with custom installation
profile.  It is in production on https://chat.museum.naturalis.nl

Limitations
-----------
This has been tested.
