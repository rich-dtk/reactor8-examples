define ssh_key::import(
  $ssh_pub_keys
)
{
  $user = $name

  user { $user:
    ensure     => 'present',
    managehome => true
  }

  ssh_key::import::authorized_key { $ssh_pub_keys:
    user => $user
  }
}

define ssh_key::import::authorized_key(
  $user
)
{
  $unset = "|${name}|"
  if $unset == "|nil|" or $unset == "||"{
    fail("unset ssh key given as parameter")
  }

  $key_with_ssh_prefix = $name
  $key = inline_template("<%= key_with_ssh_prefix.gsub(/ssh-rsa/,'').gsub(/^[ ]+/,'').gsub(/[ ].+$/,'')%>")
  $from = inline_template("<%= key_with_ssh_prefix.gsub(/^.+[ ]/,'')%>")  
  ssh_authorized_key { "${user}-${from}":
    user => $user,
    key  => $key,
    type => 'rsa'
  }
}
