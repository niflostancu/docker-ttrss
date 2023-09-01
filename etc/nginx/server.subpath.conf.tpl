root /var/www;
index index.php;

location {{NGINX_SUBPATH}} {
	alias /var/www;
	index index.php;

	location ~ [^/]\.php$ {
		try_files $uri =404;
		fastcgi_split_path_info ^(.+?\.php)(/.*)$;
		fastcgi_param SCRIPT_FILENAME $request_filename;
		fastcgi_index index.php;

		include fastcgi_params;
		fastcgi_pass ttrss;
	}
}

location {{NGINX_SUBPATH}}/cache {
	aio threads;
	internal;
}
location {{NGINX_SUBPATH}}/backups {
	internal;
}
location ~ \.ht {
	deny all;
}
