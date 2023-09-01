root /var/www;
index index.php;

location ~ [^/]\.php$ {
	try_files $uri =404;
	fastcgi_split_path_info ^(.+?\.php)(/.*)$;

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
