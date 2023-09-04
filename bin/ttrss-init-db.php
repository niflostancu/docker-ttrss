#!/usr/bin/env php
<?php
// ttrss database initialization script
chdir("/var/www");
$config = array();

// path to ttrss
// $config['SELF_URL_PATH'] = env('TTRSS_SELF_URL_PATH', 'http://localhost');
$config['DB_TYPE'] = env('TTRSS_DB_TYPE', "pgsql");
$config['DB_HOST'] = env('TTRSS_DB_HOST', "db");
$config['DB_PORT'] = env('TTRSS_DB_PORT', "5432");
$config['DB_NAME'] = env('TTRSS_DB_NAME', 'ttrss');
$config['DB_USER'] = env('TTRSS_DB_USER', 'ttrss');
$config['DB_PASS'] = env('TTRSS_DB_PASS', '');
// $config['SELF_URL_PATH'] = env('TTRSS_SELF_URL_PATH', '');

$checkPassed = false;
$timeout = 30; // seconds
while ($timeout > 0) {
    if (dbcheck($config, true)) {
        $checkPassed = true;
        break;
    }
    // sleep and retry
    sleep(2);
    $timeout = $timeout - 2;
}

$pdo = dbconnect($config);
try {
    $pdo->query('SELECT 1 FROM ttrss_feeds');
    // reached this point => table found, assume db is complete
}
catch (PDOException $e) {
    echo 'Database table not found, applying schema... ' . PHP_EOL;
    $schema = file_get_contents('sql/' . $config['DB_TYPE'] . '/schema.sql');
    $schema = preg_replace('/--(.*?);/', '', $schema);
    $schema = preg_replace('/[\r\n]/', ' ', $schema);
    $schema = trim($schema, ' ;');
    foreach (explode(';', $schema) as $stm) {
        $pdo->exec($stm);
    }
    unset($pdo);
}

# copy config.php
copy("/usr/local/share/ttrss/config.docker.php", "/var/www/config.php");

passthru('php update.php --update-schema=force-yes');

function env($name, $default = null)
{
    $v = getenv($name) ?: $default;
    if ($v === null) {
        error('The env ' . $name . ' does not exist');
    }
    return $v;
}
function error($text)
{
    echo 'Error: ' . $text . PHP_EOL;
    exit(1);
}
function dbconnect($config, $noDatabase=false)
{
    $map = array('host' => 'HOST', 'port' => 'PORT', 'dbname' => 'NAME');
    if ($noDatabase) {
        unset($map["dbname"]);
    }
    $dsn = $config['DB_TYPE'] . ':';
    foreach ($map as $d => $h) {
        if (isset($config['DB_' . $h])) {
            $dsn .= $d . '=' . $config['DB_' . $h] . ';';
        }
    }
    echo "PDO DSN: $dsn" . PHP_EOL;
    $pdo = new \PDO($dsn, $config['DB_USER'], $config['DB_PASS']);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    return $pdo;
}
function dbcheck($config, $noDatabase=false)
{
    try {
        dbconnect($config, $noDatabase);
        return true;
    }
    catch (PDOException $e) {
        return false;
    }
}
