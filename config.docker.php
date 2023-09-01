<?php
/* Hack for TTRSS_SELF_URL_PATH auto-fixing */

$ttrssSelfUrlPath = getenv("TTRSS_SELF_URL_PATH");

function isRevProxySecure() {
	return (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') 
		|| $_SERVER['SERVER_PORT'] == 443
		|| (!empty($_SERVER['HTTP_X_FORWARDED_SCHEME']) && $_SERVER['HTTP_X_FORWARDED_SCHEME'] == "https");
}

if (!empty($_SERVER["HTTP_HOST"])) {
	$proto = "http" . (isRevProxySecure()?'s':'');
	$newHost = $_SERVER["HTTP_HOST"];
	$replacement = preg_replace('/^[A-Za-z]+:\\/\\/([^\\/]+)(\\/.*)?$/', "$proto://$newHost\$2", $ttrssSelfUrlPath);
	if ($replacement) {
		$ttrssSelfUrlPath = $replacement;
	}
}
putenv("TTRSS_SELF_URL_PATH=$ttrssSelfUrlPath");

