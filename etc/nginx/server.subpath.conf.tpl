root /var/www/__404;

location / {
	return 302 $scheme://$http_host{{NGINX_SUBPATH}}/;
}
location = {{NGINX_SUBPATH}} {
	return 302 $scheme://$http_host{{NGINX_SUBPATH}}/;
}

location {{NGINX_SUBPATH}} {
	alias /var/www;
	index index.php;

	location ~ [^/]\.php$ {
		fastcgi_split_path_info ^{{NGINX_SUBPATH}}(/.+\.php)(/.*)?$;
		try_files $fastcgi_script_name =404;
		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
		fastcgi_index index.php;
		include fastcgi_params;
		fastcgi_pass ttrss;
	}

	location ~ {{NGINX_SUBPATH}}/plugins(\.local)?/.*/api/.*\.php(/|$) {
		fastcgi_split_path_info ^{{NGINX_SUBPATH}}(/.+\.php)(/.*)?$;
		set $path_info $fastcgi_path_info;
		try_files $fastcgi_script_name =404;
		fastcgi_param PATH_INFO $path_info;
		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
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
