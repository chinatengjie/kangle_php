rm -rf /etc/yum.repos.d/CentOS-Base.repo;curl -L -s http://github.itzmx.com/1265578519/mirrors/master/CentOS/CentOS6-Base-itzmx.repo -o /etc/yum.repos.d/CentOS6-Base-itzmx.repo
yum -y install wget
echo "timeout=120" >> /etc/yum.conf
yum -y update
yum -y install epel-release
chkconfig nscd off;service nscd stop;yum -y install dnsmasq;sed -i 's/#listen-address.*/listen-address=127.0.0.1/g' /etc/dnsmasq.conf;echo -e 'nameserver 127.0.0.1\nnameserver 8.8.8.8\nnameserver 2001:4860:4860::8888\nnameserver 2606:4700:4700::1111\nnameserver 1.1.1.1\nnameserver 114.114.114.114\nnameserver 119.29.29.29\noptions timeout:1 attempts:1 rotate' > /etc/resolv.conf;chkconfig dnsmasq on;service dnsmasq start
rm -rf /etc/yum.repos.d/CentOS-Base.repo
wget http://github.itzmx.com/1265578519/mirrors/master/CentOS/CentOS6-Base-itzmx.repo -O /etc/yum.repos.d/CentOS6-Base-itzmx.repo
rm -rf /etc/yum.repos.d/*pel.repo /etc/yum.repos.d/epel-testing.repo
wget http://github.itzmx.com/1265578519/mirrors/master/EPEL/epel.repo -O /etc/yum.repos.d/epel.repo
rpm -ivh http://github.itzmx.com/1265578519/repo/master/CentOS/mysql-community-release-el6-5.noarch.rpm
rm -rf /etc/yum.repos.d/mysql-community.repo /etc/yum.repos.d/mysql-community-source.repo
wget http://github.itzmx.com/1265578519/repo/master/CentOS/mysql-community.repo -O /etc/yum.repos.d/mysql-community.repo
yum clean all;yum makecache
yum -y install which file wget make automake gcc gcc-c++ pcre-devel zlib-devel openssl-devel sqlite-devel quota unzip bzip2 libaio-devel bind-utils nload iftop iotop htop lrzsz
ulimit -n 1048576
echo "* soft nofile 1048576" >> /etc/security/limits.conf
echo "* hard nofile 1048576" >> /etc/security/limits.conf
wget http://github.itzmx.com/1265578519/kangle/master/ent/e.sh -O e.sh;sh e.sh /vhs/kangle
wget http://github.itzmx.com/1265578519/kangle/master/kangle/easypanel/ep.sh -O ep.sh;sh ep.sh
yum -y install memcached php-pecl-memcache
yum -y install php-pecl-apc
rm -rf /etc/sysconfig/memcached
wget http://github.itzmx.com/1265578519/kangle/master/memcached/memcached -O /etc/sysconfig/memcached
service memcached start
chkconfig --level 2345 memcached on
yum -y install mysql mysql-server
rm -rf /etc/my.cnf
wget http://github.itzmx.com/1265578519/kangle/master/mysql/5.6/my.cnf -O /etc/my.cnf
service mysqld restart
