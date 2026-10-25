#!/bin/sh
yum -y install bzip2-devel libxml2-devel curl-devel db4-devel libjpeg-devel libpng-devel freetype-devel pcre-devel zlib-devel sqlite-devel libmcrypt-devel unzip bzip2
yum -y install mhash-devel openssl-devel
yum -y install libtool-ltdl libtool-ltdl-devel
yum -y install patch
yum -y install gcc gcc-c++ make autoconf bison re2c
PREFIX="/vhs/kangle/ext/tpl_php56401"
ZEND_ARCH="i386"
LIB="lib"
if test `arch` = "x86_64"; then
        LIB="lib64"
        ZEND_ARCH="x86_64"
fi

# 改用官方 PHP 源码（GitHub tag），而不是 itzmx.com 镜像
wget -c https://github.com/php/php-src/archive/refs/tags/php-5.6.40.tar.gz -O php-5.6.40.tar.gz
rm -rf php-5.6.40
mkdir -p php-5.6.40
tar xzf php-5.6.40.tar.gz -C php-5.6.40 --strip-components=1
cd php-5.6.40
# GitHub tag 源码不自带生成好的 configure 脚本，需要先生成（需要系统装了 autoconf/bison/re2c）
./buildconf --force

# ==================== BEGIN: php2shell enhanced-universal 补丁 ====================
# 修复 CVE-2026-109618 (OOM -> RCE) 和 CVE-2026-109619 (upload_progress UAF)
# 来源: https://github.com/Anton-Barinov/php2shell-patches
# enhanced-universal 版本做根因修复，保留 session.upload_progress / 上传进度条功能
wget -c https://raw.githubusercontent.com/Anton-Barinov/php2shell-patches/main/patches/php-5.6-enhanced-universal.patch -O ../php-5.6-enhanced-universal.patch
patch -p1 -N --dry-run < ../php-5.6-enhanced-universal.patch
if test $? != 0; then
	echo "php2shell enhanced-universal 补丁无法应用，请检查源码版本是否为 php-5.6.40"
	exit 1
fi
patch -p1 -N < ../php-5.6-enhanced-universal.patch
if test $? != 0; then
	echo "php2shell enhanced-universal 补丁应用失败"
	exit 1
fi
# ==================== END: php2shell enhanced-universal 补丁 ====================

CONFIG_CMD="./configure --prefix=$PREFIX --with-config-file-scan-dir=$PREFIX/etc/php.d --with-libdir=$LIB --enable-fastcgi --with-mysql --with-mysqli --with-pdo-mysql --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr/include/libxml2/libxml --enable-xml --disable-fileinfo --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-mbstring --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-pear --with-gettext --enable-calendar --with-openssl"
if [ -f /usr/include/mcrypt.h ]; then
        CONFIG_CMD="$CONFIG_CMD --with-mcrypt"
fi
#'./configure' --prefix=$PREFIX --with-config-file-scan-dir=$PREFIX/etc/php.d --with-libdir=$LIB '--enable-fastcgi' '--with-mysql' '--with-mysqli' --with-pdo-mysql '--with-iconv-dir' '--with-freetype-dir' '--with-jpeg-dir' '--with-png-dir' '--with-zlib' '--with-libxml-dir=/usr/include/libxml2/libxml' '--enable-xml' '--disable-fileinfo' '--enable-magic-quotes' '--enable-safe-mode' '--enable-bcmath' '--enable-shmop' '--enable-sysvsem' '--enable-inline-optimization' '--with-curl' '--with-curlwrappers' '--enable-mbregex' '--enable-mbstring' '--enable-ftp' '--with-gd' '--enable-gd-native-ttf' '--with-openssl' '--enable-pcntl' '--enable-sockets' '--with-xmlrpc' '--enable-zip' '--enable-soap' '--with-pear' '--with-gettext' '--enable-calendar'
#'./configure' --prefix=$PREFIX --with-config-file-scan-dir=$PREFIX/etc/php.d --with-libdir=$LIB '--enable-fastcgi' '--with-mysql' '--with-mysqli' --with-pdo-mysql '--with-iconv-dir' '--with-freetype-dir' '--with-jpeg-dir' '--with-png-dir' '--with-zlib' '--with-libxml-dir=/usr/include/libxml2/libxml' '--enable-xml' '--disable-fileinfo' '--enable-magic-quotes' '--enable-safe-mode' '--enable-bcmath' '--enable-shmop' '--enable-sysvsem' '--enable-inline-optimization' '--with-curl' '--with-curlwrappers' '--enable-mbregex' '--enable-mbstring' '--with-mcrypt' '--enable-ftp' '--with-gd' '--enable-gd-native-ttf' '--with-openssl' '--with-mhash' '--enable-pcntl' '--enable-sockets' '--with-xmlrpc' '--enable-zip' '--enable-soap' '--with-pear' '--with-gettext' '--enable-calendar'
$CONFIG_CMD
if test $? != 0; then
	echo $CONFIG_CMD
	echo "configure php error";
	exit 1
fi
make -j 4
make install
mkdir -p $PREFIX/etc/php.d
if [ ! -f $PREFIX/php-templete.ini ]; then
        cp php.ini-dist $PREFIX/php-templete.ini
fi
if [ ! -f $PREFIX/config.xml ]; then
        wget https://raw.githubusercontent.com/chinatengjie/kangle_php/refs/heads/main/php/5.6/5640/config.xml -O $PREFIX/config.xml
fi
cd ..
wget https://raw.githubusercontent.com/chinatengjie/kangle_php/refs/heads/main/php/5.6/5640/php-templete.ini -O $PREFIX/php-templete.ini
#install zend
wget -c http://github.itzmx.com/1265578519/kangle/master/php/5.6/5640/zend-loader-php5.6-linux-$ZEND_ARCH.tar.gz
tar zxf zend-loader-php5.6-linux-$ZEND_ARCH.tar.gz
cd zend-loader-php5.6-linux-$ZEND_ARCH
mkdir -p $PREFIX/zend
mv ZendGuardLoader.so $PREFIX/zend/ZendGuardLoader.so
cd ..
#install ioncube
wget -c http://github.itzmx.com/1265578519/kangle/master/php/5.6/5640/ioncube-$ZEND_ARCH-5.6.zip
unzip ioncube-$ZEND_ARCH-5.6.zip
mkdir -p $PREFIX/ioncube
mv ioncube_loader_lin_5.6.so $PREFIX/ioncube/ioncube_loader_lin_5.6.so
#install apcu
wget -c http://github.itzmx.com/1265578519/kangle/master/php/5.6/5640/apcu-4.0.10.tgz
tar zxf apcu-4.0.10.tgz
cd apcu-4.0.10
$PREFIX/bin/phpize
./configure --with-php-config=$PREFIX/bin/php-config
make -j 4
make install
cd ..
#install memcache
wget -c http://github.itzmx.com/1265578519/kangle/master/php/5.6/5640/memcache-3.0.8.tgz
tar zxf memcache-3.0.8.tgz
cd memcache-3.0.8
$PREFIX/bin/phpize
./configure --with-php-config=$PREFIX/bin/php-config
make -j 4
make install
cd ..
rm -rf /tmp/*
/vhs/kangle/bin/kangle -r