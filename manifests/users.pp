#
# users class
#
class manage_accounts::users (
  $users  = {},
  $manage = true,
) {
  validate_bool($manage)
  validate_hash($users)

  if $manage {
    create_resources(accounts::user, $users)
  } else
  {
    # in case we manage users on an external source (like ActiveDirectory users)
    create_resources(manage_accounts::virtual_user, $users)
  }
}
