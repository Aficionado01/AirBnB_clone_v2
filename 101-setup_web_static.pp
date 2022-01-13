#!/usr/bin/puppet apply
# AirBnB clone web server setup and configuration
exec { 'apt-get-update':
  command => 'apt-get update',
  path    => '/usr/bin:/usr/sbin:/bin',
}

package { 'nginx':
  ensure          => installed,
  provider        => 'apt',
  install_options => ['-y'],
  require         => Exec['apt-get-update'],
}

file { '/var/www':
  ensure  => directory,
  mode    => '0755',
  recurse => true,
  require => Package['nginx'],
}

file { '/var/www/html/index.html':
  content => 'Holberton School for the win!',
  require => File['/var/www'],
}

file { '/var/www/error/404.html':
  content => "Ceci n'est pas une page",
  require => File['/var/www'],
}

file { '/data/web_static/releases/test':
  ensure  => directory,
  require => Package['nginx'],
}

file { '/data/web_static/shared':
  ensure  => directory,
  require => Package['nginx'],
}

file { '/data/web_static/releases/test/index.html':
  content =>
"<!DOCTYPE html>
<html lang='en-US'>
	<head>
		<title>Home - AirBnB Clone</title>
	</head>
	<body>
		<h1>Welcome to AirBnB!</h1>
	<body>
</html>
",
  require => [
    File['/data/web_static/releases/test'],
    File['/data/web_static/shared'],
  ],
}

file { '/data/web_static/current':
  ensure  => link,
  target  => '/data/web_static/releases/test/',
  replace => true,
  require => File['/data/web_static/releases/test/index.html'],
}

exec { 'change-data-owner':
  command => 'chown -hR ubuntu:ubuntu /data',
  path    => '/usr/bin:/usr/sbin:/bin',
  require => File['/data/web_static/current'],
}

file { '/etc/nginx/sites-available/airbnbclone':
  mode    => '0644',
  content =>
"server {
	listen 80 default_server;
	listen [::]:80 default_server;

	server_name _;
	index index.html index.htm;
	error_page 404 /404.html;
	add_header X-Served-By \$hostname;

	location / {
		root /var/www/html/;
		try_files \$uri \$uri/ =404;
	}

	location /hbnb_static {
		alias /data/web_static/current/;
		try_files \$uri \$uri/ =404;
	}

	if (\$request_filename ~ redirect_me){
		rewrite ^ https://sketchfab.com/bluepeno/models permanent;
	}

	location = /404.html {
		root /var/www/error/;
		internal;
	}
}",
  require => [
    Package['nginx'],
    File['/var/www/html/index.html'],
    File['/var/www/error/404.html'],
    Exec['change-data-owner'],
  ],
}

file { '/etc/nginx/sites-enabled/airbnbclone':
  ensure  => link,
  target  => '/etc/nginx/sites-available/airbnbclone',
  replace => true,
  require => File['/etc/nginx/sites-available/airbnbclone'],
}

service { 'nginx':
  ensure     => running,
  hasrestart => true,
  subscribe  => [
    File['/etc/nginx/sites-enabled/airbnbclone'],
    Package['nginx'],
  ],
}
