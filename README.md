puppet-role_nextcloud
=====================
Puppet role definition for deployment of naturalis mattermost server.

Parameters
-------------
Sensible defaults for Naturalis in init.pp.

```
- enablessl                   Enable apache SSL modules, see SSL example
- docroot                     Documentroot, match location with 'docroot' part of the instances parameter
- mysql_root_password         Root password for mysql server
- mysql_mattermost_user       Mattermost database user
- mysql_mattermost_password   Mattermost database password
- cron                        Enable hourly cronjob for drupal installation.
```


Classes
-------------
- role_mattermost


Dependencies
-------------
- 

Docker-compose
--------------

This puppet script configures a complete docker-compose setup for mattermost. Which
consists of:

 - db
 - app
 - web
 - traefik

It is started using Foreman which creates:

 - .env file
 - docker-compose.yml
 - traefik.toml

The puppet script generates:

-

Result
------
Working webserver with mysql and nextcloud installation with custom installation
profile.  It is in production on https://chat.museum.naturalis.nl

Limitations
-----------
This has been tested.
