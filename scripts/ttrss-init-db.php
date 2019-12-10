#!/usr/bin/env php7
<?php
// ttrss database initialization script
$confpath = '/var/www/config.php';
$config = array();

// path to ttrss
$config['SELF_URL_PATH'] = env('SELF_URL_PATH', 'http://localhost');
if (getenv('DB_TYPE') !== false) {
    $config['DB_TYPE'] = getenv('DB_TYPE');
} elseif (getenv('DB_PORT_5432_TCP_ADDR') !== false) {
    // postgres container linked
    $config['DB_TYPE'] = 'pgsql';
    $eport = 5432;
} elseif (getenv('DB_PORT_3306_TCP_ADDR') !== false) {
    // mysql container linked
    $config['DB_TYPE'] = 'mysql';
    $eport = 3306;
}
if (!empty($eport)) {
    $config['DB_HOST'] = env('DB_PORT_' . $eport . '_TCP_ADDR');
    $config['DB_PORT'] = env('DB_PORT_' . $eport . '_TCP_PORT');
} elseif (getenv('DB_PORT') === false) {
    error('The env DB_PORT does not exist. Make sure to run with "--link mypostgresinstance:DB"');
} elseif (is_numeric(getenv('DB_PORT')) && getenv('DB_HOST') !== false) {
    // numeric DB_PORT provided; assume port number passed directly
    $config['DB_HOST'] = env('DB_HOST');
    $config['DB_PORT'] = env('DB_PORT');
    if (empty($config['DB_TYPE'])) {
        switch ($config['DB_PORT']) {
            case 3306:
                $config['DB_TYPE'] = 'mysql';
                break;
            case 5432:
                $config['DB_TYPE'] = 'pgsql';
                break;
            default:
                error('Database on non-standard port ' . $config['DB_PORT'] . ' and env DB_TYPE not present');
        }
    }
}
$config['DB_NAME'] = env('DB_NAME', 'ttrss');
$config['DB_USER'] = env('DB_USER', 'ttrss');
$config['DB_PASS'] = env('DB_PASS', '');
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
    $schema = file_get_contents('schema/ttrss_schema_' . $config['DB_TYPE'] . '.sql');
    $schema = preg_replace('/--(.*?);/', '', $schema);
    $schema = preg_replace('/[\r\n]/', ' ', $schema);
    $schema = trim($schema, ' ;');
    foreach (explode(';', $schema) as $stm) {
        $pdo->exec($stm);
    }
    unset($pdo);
}
// write config.php
$contents = file_get_contents($confpath);
foreach ($config as $name => $value) {
    $contents = preg_replace('/(define\s*\(\'' . $name . '\',\s*)(.*)(\);)/',
        '$1' . addcslashes(var_export($value, true), "\\$") . '$3', $contents);
}
$contents .= PHP_EOL . "define('_SKIP_SELF_URL_PATH_CHECKS', true);" . PHP_EOL;
file_put_contents($confpath, $contents);


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
