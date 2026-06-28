<?php

$databases['default']['default'] = [
  'database' => getenv('DRUPAL_DB_NAME') ?: 'drupaldb',
  'username' => getenv('DRUPAL_DB_USER') ?: 'drupal_admin',
  'password' => getenv('DRUPAL_DB_PASSWORD') ?: '',
  'prefix' => '',
  'host' => getenv('DRUPAL_DB_HOST') ?: 'db',
  'port' => getenv('DRUPAL_DB_PORT') ?: '3306',
  'namespace' => 'Drupal\\Core\\Database\\Driver\\mysql',
  'driver' => 'mysql',
];

$settings['hash_salt'] = getenv('DRUPAL_HASH_SALT') ?: 'local-development-hash-salt-change-me';

$settings['trusted_host_patterns'] = [
  '^localhost$',
  '^127\.0\.0\.1$',
  '^drupal$',
  '^.*\.elb\.amazonaws\.com$',
];

$settings['file_public_path'] = 'sites/default/files';
