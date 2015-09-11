#
# This defined type manage user
#
define manage_accounts::user (
  $ensure = 'present',
  # common attributes
  $username = "$title",
  $manage_ssh_authkeys = false,
  $ssh_authkeys = {},
  # local user specific attributes
  $uid = undef,
  $gid = undef,
  $groups = [],
  $comment = "${title}",
  $shell = '/bin/bash', 
  $pwhash = undef,
  $home = "/home/${title}", 
  $managehome = true,
  $sync_home = false,
  $sync_home_src = "",
  $home_owner = undef,
  $home_group = undef,
  $home_perms = '0700',
  # virtual user's specific attributes
  $virtual = false,
  $domain_name = "",
  $domain_principalgroup = 'domain users', ) 
{ 
  # validate some fields
  validate_re($ensure, [ "^absent$", "^present$" ], 'The $ensure parameter must be \'absent\' or \'present\'')
  validate_hash($ssh_authkeys)
  validate_bool($manage_ssh_authkeys)
  validate_bool($managehome)
  validate_bool($sync_home)
  validate_string($sync_home_src)
  validate_bool($virtual)
  validate_string($domain_name)

  # user ressource with common attributes
  user
  {
    $username:
	    ensure => $ensure,
	    home => $home,
      purge_ssh_keys => $manage_ssh_authkeys,
  }

  if !$virtual
  {
    # local user specifics
    
    # ensure that the home directory exists if we managehome
    if $managehome
    {
      if $sync_home and $sync_home_src != ""
      {
        file
        {
          $home:
	          ensure => directory,
	          owner => $home_owner,
	          group => $home_group,
	          mode => "${home_perms}",
	          source => "${sync_home_src}",
	          recurse => true,
	          recurselimit => 2,
        }
      }
      else
      {
        file 
		    { 
		      $home:
		        ensure => directory,
		        owner => $home_owner,
		        group => $home_group,
		        mode => "${home_perms}",
		    }        
      }
    }
    
    User <| title == $username |> { uid => $uid }
    
    if $gid
    {
      User <| title == $username |> { gid => $gid }
      $main_group = $gid            
    }
    else
    {
      $main_group = $title
    }
    
	  User <| title == $username |> { groups => $groups }
	  User <| title == $username |> { comment => $comment }
	  User <| title == $username |> { shell => $shell }
	  
	  if $pwhash
    {
      User <| title == $username |> { password => $pwhash }
    }
    
	  User <| title == $username |> { managehome => $managehome }
  }
  else
  {
    # virtual user specifics (like Active Directory user)
    
    # ensure that the domain home base directory exists
    if $domain_name
    {
      file
      {
        "/home/${domain_name}":
          ensure => directory,
          owner => root,
          group => root,
          mode => '0711',
      }
    }
    
    # ensure that the home directory exists
    file 
    { 
      $home:
		    ensure => directory,
		    owner => $username,
		    group => $domain_principalgroup,
		    mode => "${home_perms}",
    }
    
    $main_group = $domain_principalgroup
  }
  
  # SSH authorized keys management for the user
  if $manage_ssh_authkeys
  {
    # ensure that the .ssh and the authorized_keys exists
    file 
    {
      "${home}/.ssh":
		    ensure => directory,
		    owner => $username,
		    group => $main_group,
		    mode => '0700'
    }

	  file 
	  { 
	    "${home}/.ssh/authorized_keys":
		    ensure => present,
		    owner => $username,
		    group => $main_group,
		    mode => '0600'
	  }
	  
	  # ssh_authorized_key part
    Ssh_authorized_key 
    {
      require => File["${home}/.ssh/authorized_keys"]
    }
    
    $ssh_authkeys_defaults = 
    {
	    ensure => present,
	    user => $username,
	    type => 'ssh-rsa'
    }
    
    if $ssh_authkeys
    {
      create_resources('ssh_authorized_key', $ssh_authkeys, $ssh_authkeys_defaults)
    }
  }
}