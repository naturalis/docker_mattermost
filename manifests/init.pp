# == Class: role_mattermost
#
# Full description of class role_mattermost here.
#
# === Authors
#
# Author Name <hugo.vanduijn@naturalis.nl>
#
#

class role_mattermost (
  $compose_version              = '1.17.1',
  $repo_ensure                  = 'present',
  $repo_dir                     = '/opt/mattermost',
  $postgres_db                     = 'mattermost',
  $postgres_host                   = 'db',
  $postgres_user                   = 'mattermost_user',
  $postgres_password               = 'PASSWORD',
  $postgres_root_password          = 'ROOTPASSWORD',
  $composer_allow_superuser     = '1',
  $table_prefix                 = '',
  $protocol                     = 'http',
  $base_domain                  = '',
  $web_external_port            = '8080',
  $dev                          = '0',
  $manageenv                    = 'no',
  $enable_ssl                   = true,
  $letsencrypt_certs            = true,
  $traefik_whitelist            = false,
  $traefik_whitelist_array      = ['172.16.0.0/12'],
  $custom_ssl_certfile          = '/etc/ssl/customcert.pem',
  $custom_ssl_certkey           = '/etc/ssl/customkey.pem',
  $site_url_array        = ['chat.museum.naturalis.nl','www.chat.museum.naturalis.nl'],  # first site will be used for traefik certificate
#  $logrotate_hash               = { 'apache2'    => { 'log_path' => '/data/www/log/apache2',
#                                                      'post_rotate' => "(cd ${repo_dir}; docker-compose exec drupal service apache2 reload)",
#                                                      'extraline' => 'su root docker'},
#                                    'postgres'      => { 'log_path' => '/data/database/postgreslog',
#                                                      'post_rotate' => "(cd ${repo_dir}; docker-compose exec db postgresadmin flush-logs)",
#                                                      'extraline' => 'su root docker'}
#                                 },

# sensu check settings
  $checks_defaults    = {
    interval      => 600,
    occurrences   => 3,
    refresh       => 60,
    handlers      => ['default'],
    subscribers   => ['appserver'],
    standalone    => true },

){

  include 'docker'
  include 'stdlib'

  Exec {
    path => ['/usr/local/bin/','/usr/bin','/bin'],
    cwd  => $role_mattermost::repo_dir,
  }

  file { ['/data','/data/database'] :
    ensure              => directory,
    owner               => 'root',
    group               => 'wheel',
    mode                => '0775',
    require             => Class['docker'],
  }

  file { $role_mattermost::repo_dir:
    ensure              => directory,
    mode                => '0770',
  }


# define ssl certificate location
  if ( $letsencrypt_certs == true ) {
    $ssl_certfile = "/etc/letsencrypt/live/${site_url_array[0]}/fullchain.pem"
    $ssl_certkey = "/etc/letsencrypt/live/${site_url_array[0]}/privkey.pem"
  }else{
    $ssl_certfile = $custom_ssl_certfile
    $ssl_certkey = $custom_ssl_certkey
  }

 file { "${role_mattermost::repo_dir}/traefik.toml" :
    ensure   => file,
    content  => template('role_mattermost/traefik.toml.erb'),
    require  => File[$role_mattermost::repo_dir],
    notify   => Exec['Restart traefik on change'],
  }

 file { "${role_mattermost::repo_dir}/docker-compose.yml" :
    ensure   => file,
    content  => template('role_mattermost/docker-compose.yml.erb'),
    require  => File[$role_mattermost::repo_dir],
    notify   => Exec['Restart containers on change'],
  }

  file { "${role_mattermost::repo_dir}/.env":
    ensure   => file,
    mode     => '0600',
    replace  => $role_mattermost::manageenv,
    content  => template('role_mattermost/env.erb'),
    require  => File['/opt/mattermost/docker-compose.yml'],
    notify   => Exec['Restart containers on change'],
  }

  class {'docker::compose':
    ensure      => present,
    version     => $role_mattermost::compose_version,
    notify      => Exec['apt_update'],
    require     => File["${role_mattermost::repo_dir}/.env"]
  }

  docker_network { ['web']:
    ensure   => present,
  }

  ensure_packages(['git','python3'], { ensure => 'present' })

  docker_compose { "${role_mattermost::repo_dir}/docker-compose.yml":
    ensure      => present,
    options     => "-p ${role_mattermost::repo_dir} ",
    require     => [
      File[$role_mattermost::repo_dir],
      Docker_network['web'],
      File["${role_mattermost::repo_dir}/.env"]
    ]
  }

  exec { 'Pull containers' :
    command  => 'docker-compose pull',
    schedule => 'everyday',
  }

  exec { 'Up the containers to resolve updates' :
    command  => 'docker-compose up -d',
    schedule => 'everyday',
    require  => [
      Exec['Pull containers'],
      File[$role_mattermost::repo_dir],
      Docker_network['web'],
      File["${role_mattermost::repo_dir}/.env"]
    ]
  }

  exec {'Restart containers on change':
    refreshonly => true,
    command     => 'docker-compose up -d',
    require     => [
      File[$role_mattermost::repo_dir],
      Docker_network['web'],
      File["${role_mattermost::repo_dir}/.env"]
    ]
  }

  exec {'Restart traefik on change':
    refreshonly => true,
    command     => 'docker-compose restart traefik',
    require     => [
      File[$role_mattermost::repo_dir],
      Docker_network['web'],
      File["${role_mattermost::repo_dir}/.env"]
    ]
  }

  exec {'Start containers if none are running':
    command     => 'docker-compose up -d',
    onlyif      => 'docker-compose ps | wc -l | grep -c 2',
    require     => [
      File[$role_mattermost::repo_dir],
      Docker_network['web'],
      File["${role_mattermost::repo_dir}/.env"]
    ]
  }

  # deze gaat per dag 1 keer checken
  # je kan ook een range aan geven, bv tussen 7 en 9 's ochtends
  schedule { 'everyday':
     period  => daily,
     repeat  => 1,
     range => '5-7',
  }

#  create_resources('role_mattermost::logrotate', $logrotate_hash)


# update when configured
#  if ( $role_mattermost::updatesecurity == true ) or ( $role_mattermost::updateall == true ) {
#      class { 'role_mattermost::update':}
#    }

}
