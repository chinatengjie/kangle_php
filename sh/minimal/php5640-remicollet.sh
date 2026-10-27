#!/bin/sh
yum -y install epel-release
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

# PHP 5.6 的 GitHub 源码包没有预生成 parser，configure 需要 bison 2.4 ~ 2.7
# CentOS 7 自带 bison 3.0 被 PHP 5.6 排除，这时临时编译 bison 2.7（只对本脚本生效）
BISON_PREFIX="/usr/local/bison27"
need_bison27=0

if command -v bison >/dev/null 2>&1; then
        bv=$(bison --version | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1)
        bmaj=${bv%%.*}
        bmin=${bv#*.}
        bnum=$((bmaj * 100 + bmin))
        # 低于 2.4 或 3.0 及以上，都改用 2.7
        if [ "$bnum" -lt 204 ] || [ "$bnum" -ge 300 ]; then
                need_bison27=1
        fi
else
        need_bison27=1
fi

if [ "$need_bison27" = "1" ]; then
        if [ ! -x "$BISON_PREFIX/bin/bison" ]; then
                # 仅在需要编译 bison 2.7 时才安装 m4
                yum -y install m4
                BISON_BUILD_DIR=$(mktemp -d /root/bison-build.XXXXXX)
                (
                        cd "$BISON_BUILD_DIR" || exit 1
                        wget -c https://ftp.gnu.org/gnu/bison/bison-2.7.tar.gz -O bison-2.7.tar.gz || exit 1
                        tar xzf bison-2.7.tar.gz && cd bison-2.7 || exit 1
                        ./configure --prefix="$BISON_PREFIX" || exit 1
                        make -j4 || exit 1
                        make install || exit 1
                )
                if [ $? != 0 ]; then
                        echo "编译 bison 2.7 失败"
                        exit 1
                fi
                rm -rf "$BISON_BUILD_DIR"
        fi
        export PATH="$BISON_PREFIX/bin:$PATH"
fi
echo "当前使用: $(bison --version | head -n1)"
# ==================== END: bison 版本检查 ====================

# 源码改用 Remi Collet 维护的安全回合分支（remicollet/php-src-security），
# 在官方 5.6.40 基础上额外回合了大量 2019~2020 年间的历史 CVE 修复
# (FPM RCE CVE-2019-11043、多个 EXIF 堆溢出/UAF、iconv 整数溢出等)，
# 比纯官方 vanilla 源码安全覆盖更全面
wget -c https://codeload.github.com/remicollet/php-src-security/tar.gz/refs/tags/php-5.6.40-16 -O php-5.6.40.tar.gz
rm -rf php-5.6.40
mkdir -p php-5.6.40
tar xzf php-5.6.40.tar.gz -C php-5.6.40 --strip-components=1
cd php-5.6.40
# GitHub tag 源码不自带生成好的 configure 脚本，需要先生成（需要系统装了 autoconf/bison/re2c）
./buildconf --force

# ==================== BEGIN: php2shell minimal 补丁 (Remi's tree 版本) ====================
# 修复 CVE-2026-109618 (OOM -> RCE)、CVE-2026-109619 (upload_progress UAF)
# 和 CVE-2026-115560 (序列化器分隔符混淆 RCE)
# 来源: https://github.com/Anton-Barinov/php2shell-patches
# minimal-remicollet 版本专门适配 remicollet/php-src-security 这棵源码树的基线，
# 做最小必要修复，直接禁用 session.upload_progress 上传进度条功能
# (本机不需要上传进度条功能，三个 CVE 均可防住)
wget -c https://raw.githubusercontent.com/Anton-Barinov/php2shell-patches/main/patches/php-5.6-minimal-remicollet.patch -O ../php-5.6-minimal-remicollet.patch
patch -p1 -N --dry-run < ../php-5.6-minimal-remicollet.patch
if test $? != 0; then
	echo "php2shell minimal-remicollet 补丁无法应用，请检查源码版本是否为 remicollet/php-src-security php-5.6.40-16"
	exit 1
fi
patch -p1 -N < ../php-5.6-minimal-remicollet.patch
if test $? != 0; then
	echo "php2shell minimal-remicollet 补丁应用失败"
	exit 1
fi
# ==================== END: php2shell minimal 补丁 (Remi's tree 版本) ====================

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