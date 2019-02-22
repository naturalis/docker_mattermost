# mattermost Logrotate creation
define role_mattermost::logrotate (
  $log_path,
  $post_rotate      = undef,
  $pre_rotate       = undef,
  $extraline        = undef,
  $rotate           = 14,
){

# configure logrotate
  file { "/etc/logrotate.d/${title}":
    mode        => '0600',
    content     => template('role_mattermost/logrotate.erb'),
  }

}
