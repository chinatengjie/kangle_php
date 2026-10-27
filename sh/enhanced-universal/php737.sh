#!/bin/sh
yum -y install epel-release
yum -y install bzip2-devel libxml2-devel curl-devel db4-devel libjpeg-devel libpng-devel freetype-devel pcre-devel zlib-devel sqlite-devel libmcrypt-devel unzip bzip2
yum -y install mhash-devel openssl-devel
yum -y install libtool-ltdl libtool-ltdl-devel
yum -y install patch gcc gcc-c++ make autoconf bison re2c
yum -y remove libzip-devel
wget -c http://github.itzmx.com/1265578519/kangle/master/php/7.3/737/libzip-1.3.2.tar.gz -O libzip-1.3.2.tar.gz
tar xvf libzip-1.3.2.tar.gz
cd libzip-1.3.2
./configure
make -j 4
make install
cd ..
mv -f /usr/lib64/libzip.so.5 /usr/lib64/libzip.so.5.bak
ln -s /usr/local/lib/libzip.so.5 /usr/lib64/libzip.so.5
ln -s /usr/local/lib/pkgconfig/libzip.pc /usr/lib64/pkgconfig/libzip.pc
echo '/usr/local/lib' > /etc/ld.so.conf.d/libzip.conf
ldconfig -v

# ==================== BEGIN: autoconf 版本检查 ====================
# PHP 7.3 的 buildconf 需要 autoconf >= 2.68，CentOS 6 自带 2.63
# 版本不够时先编译 autoconf 2.69 到 /usr/local，并放到 PATH 最前面
# 后面编译 apcu/memcache 等扩展时 phpize 也会用到它
av=$(autoconf --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1)
amaj=${av%%.*}
amin=${av#*.}
anum=$((${amaj:-0} * 100 + ${amin:-0}))
if [ "$anum" -lt 268 ]; then
        yum -y install m4 perl
        (
                cd /root || exit 1
                wget -c http://github.itzmx.com/1265578519/kangle/master/php/7.3/737/autoconf-2.69.tar.gz -O autoconf-2.69.tar.gz || exit 1
                tar zxf autoconf-2.69.tar.gz && cd autoconf-2.69 || exit 1
                ./configure --prefix=/usr/local || exit 1
                make -j4 || exit 1
                make install || exit 1
        )
        if [ $? != 0 ]; then
                echo "编译 autoconf 2.69 失败"
                exit 1
        fi
        export PATH=/usr/local/bin:$PATH
        hash -r
fi
echo "当前使用: $(autoconf --version | head -n1)"
# ==================== END: autoconf 版本检查 ====================

PREFIX="/vhs/kangle/ext/tpl_php7371"
ZEND_ARCH="i386"
LIB="lib"
if test `arch` = "x86_64"; then
        LIB="lib64"
        ZEND_ARCH="x86_64"
fi

# 改用官方 PHP 源码（GitHub tag），而不是 itzmx.com 镜像的 7.3.7
wget -c https://github.com/php/php-src/archive/refs/tags/php-7.3.33.tar.gz -O php-7.3.33.tar.gz
mkdir -p php-7.3.33
tar xzf php-7.3.33.tar.gz -C php-7.3.33 --strip-components=1
cd php-7.3.33
# GitHub tag 源码不自带生成好的 configure 脚本，需要先生成（需要 autoconf>=2.68/bison/re2c）
./buildconf --force
if [ ! -f configure ]; then
	echo "buildconf 失败，未生成 configure（请检查 autoconf/bison/re2c 版本）"
	exit 1
fi

# ==================== BEGIN: php2shell enhanced-universal 补丁 ====================
# 修复 CVE-2026-109618 (OOM -> RCE) 和 CVE-2026-109619 (upload_progress UAF)
# 来源: https://github.com/Anton-Barinov/php2shell-patches
# enhanced-universal 版本做根因修复，保留 session.upload_progress / 上传进度条功能
wget -c https://raw.githubusercontent.com/Anton-Barinov/php2shell-patches/main/patches/php-7.3-enhanced-universal.patch -O ../php-7.3-enhanced-universal.patch
patch -p1 -N --dry-run < ../php-7.3-enhanced-universal.patch
if test $? != 0; then
	echo "php2shell enhanced-universal 补丁无法应用，请检查源码版本是否为 php-7.3.33"
	exit 1
fi
patch -p1 -N < ../php-7.3-enhanced-universal.patch
if test $? != 0; then
	echo "php2shell enhanced-universal 补丁应用失败"
	exit 1
fi
if find . -name '*.rej' | grep -q .; then
	echo "补丁产生了 .rej 文件，应用不完整"
	exit 1
fi
# ==================== END: php2shell enhanced-universal 补丁 ====================

CONFIG_CMD="./configure --prefix=$PREFIX --with-config-file-scan-dir=$PREFIX/etc/php.d --with-libdir=$LIB --enable-fastcgi --with-mysql --with-mysqli --with-pdo-mysql --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr/include/libxml2/libxml --enable-xml --disable-fileinfo --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-mbstring --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-pear --with-gettext --enable-calendar --with-openssl"
if [ -f /usr/include/mcrypt.h ]; then
        CONFIG_CMD="$CONFIG_CMD --with-mcrypt"
fi
$CONFIG_CMD
if test $? != 0; then
	echo $CONFIG_CMD
	echo "configure php error";
	exit 1
fi
make -j 4
if test $? != 0; then
	echo "make php error";
	exit 1
fi
make install
mkdir -p $PREFIX/etc/php.d
if [ ! -f $PREFIX/php-templete.ini ]; then
        cp php.ini-dist $PREFIX/php-templete.ini
fi
if [ ! -f $PREFIX/config.xml ]; then
        wget https://raw.githubusercontent.com/chinatengjie/kangle_php/refs/heads/main/php/7.3/737/config.xml -O $PREFIX/config.xml
fi
cd ..
wget https://raw.githubusercontent.com/chinatengjie/kangle_php/refs/heads/main/php/7.3/737/php-templete.ini -O $PREFIX/php-templete.ini
#install ioncube
wget -c http://github.itzmx.com/1265578519/kangle/master/php/7.3/737/ioncube-$ZEND_ARCH-7.3.zip
unzip ioncube-$ZEND_ARCH-7.3.zip
mkdir -p $PREFIX/ioncube
mv ioncube_loader_lin_7.3.so $PREFIX/ioncube/ioncube_loader_lin_7.3.so
#install apcu
wget -c http://github.itzmx.com/1265578519/kangle/master/php/7.3/737/apcu-5.1.17.tgz
tar zxf apcu-5.1.17.tgz
cd apcu-5.1.17
$PREFIX/bin/phpize
./configure --with-php-config=$PREFIX/bin/php-config
make -j 4
make install
cd ..
#install libmemcached
wget -c http://github.itzmx.com/1265578519/kangle/master/php/7.3/737/libmemcached-1.0.18.tar.gz
tar -zxvf libmemcached-1.0.18.tar.gz
cd libmemcached-1.0.18
./configure
make -j 4
make install
cd ..
#install memcached
wget -c http://github.itzmx.com/1265578519/kangle/master/php/7.3/737/php-memcached-3.1.3-dev.zip
unzip -o php-memcached-3.1.3-dev.zip
cd php-memcached-3.1.3-dev
$PREFIX/bin/phpize
./configure --with-php-config=$PREFIX/bin/php-config --disable-memcached-sasl
make -j 4
make install
cd ..
#install memcache
wget -c http://github.itzmx.com/1265578519/kangle/master/php/7.3/737/php-memcache-4.0.4-dev.zip
unzip -o php-memcache-4.0.4-dev.zip
cd php-memcache-4.0.4-dev
$PREFIX/bin/phpize
./configure --with-php-config=$PREFIX/bin/php-config
make -j 4
make install
cd ..
rm -rf /tmp/*
/vhs/kangle/bin/kangle -r