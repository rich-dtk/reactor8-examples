# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class hadoop_zookeeper::client(
  $ensemble
) inherits hadoop_zookeeper::params
{
  notify { $ensemble: }
  package { "zookeeper":
    ensure  => latest,
    require => Package["jdk"],
  } 
} 
class hadoop_zookeeper::peer(
  $peer_addrs     = [],
  $peer_ids       = []
)
{
}

class hadoop_zookeeper::server(
  $myid           = 1, 
  $kerberos_realm = ""
) inherits hadoop_zookeeper::params
{

  include hadoop_zookeeper::peer
  $this_peer = $::ec2_public_hostname

  $ensemble = append_each(":${default_zk_ports}",array_concat($hadoop_zookeeper::peer::peer_addrs,[$this_peer]))

  r8::export_variable {'hadoop_zookeeper::server::ensemble': }

  $myid_array = array_concat($hadoop_zookeeper::peer::peer_ids,[$myid])

  package { "zookeeper-server":
    ensure  => latest,
    require => Package["jdk"],
  }

  service { "zookeeper-server":
    ensure     => running,
    require    => [ Package["zookeeper-server"], 
                    Exec["zookeeper-server-initialize"] ],
    subscribe  => [ File["/etc/zookeeper/conf/zoo.cfg"],
                   File["/var/lib/zookeeper/myid"] ],
    hasrestart => true,
    hasstatus  => true
  } 

  file { "/etc/zookeeper/conf/zoo.cfg":
    content => template("hadoop_zookeeper/zoo.cfg"),
    require => Package["zookeeper-server"],
  }

  file { "/var/lib/zookeeper/myid":
    content => inline_template("<%= myid %>"),
    require => Package["zookeeper-server"],
  }
    
  exec { "zookeeper-server-initialize":
    command => "/usr/bin/zookeeper-server-initialize",
    user    => "zookeeper",
    creates => "/var/lib/zookeeper/version-2",
    require => Package["zookeeper-server"],
  }

  if ($kerberos_realm) {
    require kerberos::client

    kerberos::host_keytab { "zookeeper":
      spnego => true,
      notify => Service["zookeeper-server"],
    }

    file { "/etc/zookeeper/conf/java.env":
      source  => "puppet:///modules/hadoop_zookeeper/java.env",
      require => Package["zookeeper-server"],
      notify  => Service["zookeeper-server"],
    }

    file { "/etc/zookeeper/conf/jaas.conf":
      content => template("hadoop_zookeeper/jaas.conf"),
      require => Package["zookeeper-server"],
      notify  => Service["zookeeper-server"],
    }
  }
}

