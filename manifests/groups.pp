#
# This module manages accounts
#
# Parameters: none
#
# Actions:
#
# Requires: see Modulefile
#
# Sample Usage:
#
class manage_accounts::groups (
  $groups = {},
  $manage = true,
  ) {
  validate_bool($manage)
  validate_hash($groups)

  if $manage {
    create_resources(accounts::group, $groups)
  }
}
