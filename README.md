centos6


echo -e "options timeout:1 attempts:1 rotate\nnameserver 8.8.8.8\nnameserver 114.114.114.114" >/etc/resolv.conf;

rm -rf /etc/yum.repos.d/CentOS-Base.repo;curl -L -s https://raw.githubusercontent.com/chinatengjie/kangle_php/refs/heads/main/repo/CentOS6-Vault.repo -o /etc/yum.repos.d/CentOS6-Vault.repo

centos7

curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo

curl -o /etc/yum.repos.d/CentOS-Base.repo https://repo.huaweicloud.com/repository/conf/CentOS-7-reg.repo

curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.cloud.tencent.com/repo/centos7_base.repo

curl -o /etc/yum.repos.d/CentOS-Base.repo https://raw.githubusercontent.com/chinatengjie/kangle_php/refs/heads/main/repo/CentOS7-Base-vault.repo


yum clean all

yum makecache

yum install wget nano -y


minimal
--------------------------------------------------------------------------
```bash
wget https://raw.githubusercontent.com/chinatengjie/kangle_php/refs/heads/main/sh/minimal/php5640.sh -O php5640.sh;sh php5640.sh
```

```bash
wget https://raw.githubusercontent.com/chinatengjie/kangle_php/refs/heads/main/sh/minimal/php7130.sh -O php7130.sh;sh php7130.sh
```

```bash
wget https://raw.githubusercontent.com/chinatengjie/kangle_php/refs/heads/main/sh/minimal/php737.sh -O php737.sh;sh php737.sh
```

采用php5640remicollet

https://github.com/remicollet/php-src-security/tree/PHP-5.6-security-backports

wget https://raw.githubusercontent.com/chinatengjie/kangle_php/refs/heads/main/sh/minimal/php5640-remicollet.sh -O php5640-remicollet.sh;sh php5640-remicollet.sh openssl 有问题未修复

--------------------------------------------------------------------------
enhanced-universal版本改动较大 如果需要上传进度条就使用这个
wget https://raw.githubusercontent.com/chinatengjie/kangle_php/refs/heads/main/sh/enhanced-universal/php5640.sh -O php5640.sh;sh php5640.sh

wget https://raw.githubusercontent.com/chinatengjie/kangle_php/refs/heads/main/sh/enhanced-universal/php7130.sh -O php7130.sh;sh php7130.sh

wget https://raw.githubusercontent.com/chinatengjie/kangle_php/refs/heads/main/sh/enhanced-universal/php737.sh -O php737.sh;sh php737.sh


编译后打包

```bash
cd /vhs/kangle/ext
tar czf tpl_php56401.tar.gz tpl_php56401
tar czf tpl_php71301.tar.gz tpl_php71301
tar czf tpl_php7371.tar.gz tpl_php7371
ls -la tpl_php56401.tar.gz tpl_php71301.tar.gz tpl_php7371.tar.gz
md5sum tpl_php*.tar.gz
```