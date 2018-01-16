### Nginx 源码编译安装

```
./configure --prefix=/opt/nginx --sbin-path=/opt/nginx/sbin/nginx --conf-path=/opt/nginx/conf/nginx.conf --error-log-path=/opt/nginx/logs/error.log  --pid-path=/opt/nginx/logs/nginx.pid --lock-path=/var/lock/subsys/nginx --with-http_ssl_module --with-http_flv_module --with-http_gzip_static_module --http-log-path=/opt/nginx/logs/access.log --with-http_stub_status_module --with-pcre
```
