#
# This defined type manage a local group
#
define manage_accounts::group (
  $groupname = $title,
  $ensure    = 'present',
  $gid       = undef,
  )
  {
    validate_re($ensure, [ '^absent$', '^present$' ], 'The $ensure parameter must be \'absent\' or \'present\'')
    
    # to be sure that we'll don't have duplicate groups
    ensure_resource('group', $groupname, {'ensure' => $ensure, 'gid' => $gid, })
  }