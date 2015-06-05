#
# This class manage users
#
class manage_accounts::users (
  $users  = {},
  $manage = true,
) {
  validate_bool($manage)
  validate_hash($users)

  create_resources(manage_accounts::user, $users)
}
