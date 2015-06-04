#
# virtual_user defined type
#
define manage_accounts::virtual_user (
  $ssh_keys = {},
  $username = $title,
  $domainname = undef,
  $defaultgroup = "Domain Users",
  $home_permissions = $::osfamily ? {
                        'Debian' => '0755',
                        'RedHat' => '0700',
                        default  => '0700',
                      },
  $ensure = present,
  $recurse_permissions = false,
  ) {
  validate_re($ensure, [ '^absent$', '^present$' ], 'The $ensure parameter must be \'absent\' or \'present\'')
  validate_hash($ssh_keys)

  if $domainname {
    # ensure that the domain home directory exists
    file { "/home/${domainname}":
	    ensure  => directory,
	    owner   => root,
	    group   => root,
	    mode    => "0711",
	  }

    $home_dir = "/home/${domainname}/${username}"
  }
  else {
    $home_dir = "/home/${username}"
  }
    
  # ensure that the user home directory exists
  file { $home_dir:
    ensure  => directory,
    owner   => $username,
    group   => $defaultgroup,
    recurse => $recurse_permissions,
    mode    => $home_permissions,
  }
  
  file { "${home_dir}/.ssh":
    ensure  => directory,
    owner   => $username,
    group   => $username,
    mode    => '0700',
    require => File[$home_dir],
  }

  file { "${home_dir}/.ssh/authorized_keys":
    ensure  => present,
    owner   => $username,
    group   => $username,
    mode    => '0600',
    require => File["${home_dir}/.ssh"],
  }
  
  Ssh_authorized_key {
    require =>  File["${home_dir}/.ssh/authorized_keys"]
  }
  
  $ssh_key_defaults = {
    ensure => present,
    user   => $username,
    'type' => 'ssh-rsa'
  }
  if $ssh_key {
    # for unique resource naming
    $suffix = empty($ssh_key['comment']) ? {
      undef   => $ssh_key['type'],
      default => $ssh_key['comment']
    }
    ssh_authorized_key { "${username}_${suffix}":
      ensure => present,
      user   => $username,
      type   => $ssh_key['type'],
      key    => $ssh_key['key'],
    }
  }
  
  if $ssh_keys {
    create_resources('ssh_authorized_key', $ssh_keys, $ssh_key_defaults)
  }
}