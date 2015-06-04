# Class: manage_accounts
#
# This module manages local and virtual accounts
#
class manage_accounts (
  $manage_users  = true,
  $manage_groups = true,
  $users         = {},
  $groups        = {},
  )
  {
  validate_bool($manage_users)
  validate_bool($manage_groups)
  validate_hash($users)
  validate_hash($groups)

  class { 'manage_accounts::groups':
    manage => $manage_groups,
    groups => $groups,
  }

  class { 'manage_accounts::users':
    manage  => $manage_users,
    users   => $users,
    require => Class['manage_accounts::groups']
  }
}

