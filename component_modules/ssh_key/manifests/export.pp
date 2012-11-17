define ssh_key::export() 
{
  $user = $name
  $user_home = "/home/${user}"
  $ssh_dir = "${user_home}/.ssh"
  $priv_key = "${ssh_dir}/id_rsa"
  $pub_key = "${ssh_dir}/id_rsa.pub"

  user { $user:
    ensure     => 'present',
    managehome => true
  }

  file { $ssh_dir:
    ensure  => 'directory',
    owner   => $user,
  }

  exec { "ssh-key-gen rsa ${user}": 
    command => "ssh-keygen -q -t rsa -f ${priv_key} -P ''",
    creates => $priv_key,
    path    => ['/usr/bin'],
    user    => $user,
    require => File[$ssh_dir]
  }

  r8_export_file { "ssh_key.export.ssh_pub_key": 
    filename       => $pub_key,
    definition_key => $name,
    require        => Exec["ssh-key-gen rsa ${user}"]
  }
}