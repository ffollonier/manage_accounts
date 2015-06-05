#
# This class manage groups
#
class manage_accounts::groups (
  $groups = {},
  $manage = true,
  ) {
  validate_bool($manage)
  validate_hash($groups)

  if $manage {
    create_resources(manage_accounts::group, $groups)
  }
}
