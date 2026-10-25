curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/CentOS-Base.repo https://repo.huaweicloud.com/repository/conf/CentOS-7-reg.repo
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.cloud.tencent.com/repo/centos7_base.repo

yum clean all
yum makecache
yum install wget nano -y


wget https://raw.githubusercontent.com/chinatengjie/kangle_php/refs/heads/main/sh/centos7/php5640.sh -O php5640.sh;sh php5640.sh

wget https://raw.githubusercontent.com/chinatengjie/kangle_php/refs/heads/main/sh/centos7/php7130.sh -O php7130.sh;sh php7130.sh

wget https://raw.githubusercontent.com/chinatengjie/kangle_php/refs/heads/main/sh/centos7/php737.sh -O php737.sh;sh php737.sh
