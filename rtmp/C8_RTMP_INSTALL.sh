#!/bin/bash
sudo yum update -y
sudo yum groupinstall 'Development Tools'  -y
sudo yum install epel-release -y
sudo yum install wget git unzip perl perl-devel perl-ExtUtils-Embed libxslt libxslt-devel libxml2 libxml2-devel gd gd-devel pcre-devel GeoIP GeoIP-devel -y
wget -nc http://nginx.org/download/nginx-1.18.0.tar.gz
tar -xvzf nginx-1.18.0.tar.gz
wget -nc https://ftp.pcre.org/pub/pcre/pcre-8.42.zip
wget -nc https://www.zlib.net/zlib-1.2.11.tar.gz
unzip -o pcre-8.42.zip
tar -xvzf zlib-1.2.11.tar.gz
wget -nc https://www.openssl.org/source/openssl-1.1.0h.tar.gz
tar -xzvf openssl-1.1.0h.tar.gz
git clone https://github.com/sergey-dryabzhinsky/nginx-rtmp-module.git
cd nginx-1.18.0/
./configure --prefix=/etc/nginx \
--sbin-path=/usr/sbin/nginx \
--modules-path=/usr/lib64/nginx/modules \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/run/nginx.lock \
--user=nginx \
--group=nginx \
--build=CentOS \
--builddir=nginx-1.18.0 \
--with-select_module \
--with-poll_module \
--with-threads \
--with-file-aio \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_realip_module \
--with-http_addition_module \
--with-http_xslt_module=dynamic \
--with-http_image_filter_module=dynamic \
--with-http_geoip_module=dynamic \
--with-http_sub_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_mp4_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_auth_request_module \
--with-http_random_index_module \
--with-http_secure_link_module \
--with-http_degradation_module \
--with-http_slice_module \
--with-http_stub_status_module \
--http-log-path=/var/log/nginx/access.log \
--http-client-body-temp-path=/var/cache/nginx/client_temp \
--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
--with-mail=dynamic \
--with-mail_ssl_module \
--with-stream=dynamic \
--with-stream_ssl_module \
--with-stream_realip_module \
--with-stream_geoip_module=dynamic \
--with-stream_ssl_preread_module \
--with-compat \
--with-pcre=../pcre-8.42 \
--with-pcre-jit \
--with-zlib=../zlib-1.2.11 \
--with-openssl=../openssl-1.1.0h \
--with-openssl-opt=no-nextprotoneg \
--add-module=../nginx-rtmp-module \
--with-debug
make
make install
nginx -V
# Write file
cat << EOF > /lib/systemd/system/nginx.service
[Unit]
Description=nginx - high performance web server
Documentation=https://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx.conf
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID

[Install]
WantedBy=multi-user.target
EOF

# create nginx user
id -u nginx &>/dev/null || useradd -s /bin/false nginx
mkdir -p /var/cache/nginx

systemctl daemon-reload
systemctl start nginx
systemctl enable nginx
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
cat << EOF > /etc/nginx/nginx.conf
worker_processes auto;
events {
    worker_connections 1024;
}

rtmp {
    server {
        listen 1935; 
        application live {
            live on; 
            record off;
            ### REMOVE <> SYMBOLS ###
            # youtube RTMP
            #push <youtube rtmp link>/<stream key>;
            # twitch RTMP
            #push <twitchs rtmp link>/<stream key>;
            # facebook RTMP
            #push <facebook rtmp link>/<stream key>;
        }
    }
}
EOF
systemctl restart nginx
