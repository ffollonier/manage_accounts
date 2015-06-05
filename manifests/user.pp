#
# This defined type manage user
#
define manage_accounts::user (
  $ensure = "present",
  # common attributes
  $username = "$title",
  $manage_ssh_authkeys = false,
  $ssh_authkeys = {},
  # local user specific attributes
  $uid = undef,
  $gid = undef,
  $groups = [],
  $comment = "${title}",
  $shell = "/bin/bash", 
  $pwhash = "",
  $home = "/home/${title}", 
  $managehome = true,
  # virtual user's specific attributes
  $virtual = false,
  $domain_name = undef,
  $domain_principalgroup = "Domain Users", ) 
{
  # define some local variables
  $home_dir=""
  $main_group=""

  # validate some fields
  validate_re($ensure, [ "^absent$", "^present$" ], 'The $ensure parameter must be \'absent\' or \'present\'')
  validate_hash($ssh_authkeys)

  # user ressource with common attributes
  user
  { 
    $username:
	    ensure  => $ensure,
	    purge_ssh_keys => $manage_ssh_authkeys,
  }
  

  if !$virtual
  {
    # local user specifics
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
	  
	  if $pwhash != ""
    {
      User <| title == $username |> { password => $pwhash }
    }
    
	  User <| title == $username |> { managehome => $managehome }
	  User <| title == $username |> { home => $home }
	  $home_dir = $home
  }
  else
  {
    # virtual user specifics (like Active Directory user)

    # ensure that the home dir for the virtual user exists
    if $domain_name 
    {
	    # ensure that the domain home directory exists
	    file 
	    { 
	      "/home/${domain_name}":
		      ensure  => directory,
		      owner   => root,
		      group   => root,
		      mode    => "0711",
	    }

      $home_dir = "/home/${domain_name}/${username}"
    }
    else 
    {
      $home_dir = "/home/${username}"
    }
    
    # ensure that the home directory exists
    file 
    { 
      $home_dir:
		    ensure  => directory,
		    owner   => $username,
		    group   => $domain_principalgroup,
		    mode    => "0700",
    }
    
    $main_group = $domain_principalgroup
  }
  
  # SSH authorized keys management for the user
  if $manage_ssh_authkeys
  {
    # ensure that the .ssh and the authorized_keys exists
    file 
    {
      "${home_dir}/.ssh":
		    ensure  => directory,
		    owner   => $username,
		    group   => $main_group,
		    mode    => '0700',
		    require => File[$home_dir],
    }

	  file 
	  { 
	    "${home_dir}/.ssh/authorized_keys":
		    ensure  => present,
		    owner   => $username,
		    group   => $main_group,
		    mode    => '0600',
		    require => File["${home_dir}/.ssh"],
	  }
	  
	  # ssh_authorized_key part
    Ssh_authorized_key 
    {
      require => File["${home_dir}/.ssh/authorized_keys"]
    }
    
    $ssh_authkeys_defaults = 
    {
	    ensure => present,
	    user   => $username,
	    type   => "ssh-rsa"
    }
    
    if $ssh_authkeys
    {
      create_resources("ssh_authorized_key", $ssh_authkeys, $ssh_authkeys_defaults)
    }
  }
}