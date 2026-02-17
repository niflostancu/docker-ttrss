root /var/www;
index index.php;

location ~ [^/]\.php$ {
	fastcgi_split_path_info ^(.+?\.php)(/.*)?$;
	try_files $fastcgi_script_name =404;
	fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
	fastcgi_index index.php;
	include fastcgi_params;
	fastcgi_pass ttrss;
}

location ~ /plugins(\.local)?/.*/api/.*\.php(/|$) {
	fastcgi_split_path_info ^(/.+\.php)(/.*)?$;
	set $path_info $fastcgi_path_info;
	try_files $fastcgi_script_name =404;
	fastcgi_param PATH_INFO $path_info;
	fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
	fastcgi_index index.php;

	include fastcgi_params;
	fastcgi_pass ttrss;
}

location /cache {
	aio threads;
	internal;
}
location /backups {
	internal;
}
location ~ \.ht {
	deny all;
}
