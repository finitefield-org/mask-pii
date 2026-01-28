<?php

declare(strict_types=1);

require_once __DIR__ . "/../vendor/autoload.php";

use MaskPII\Masker;

$masker = (new Masker())
    ->maskEmails()
    ->maskPhones();

$input = "Contact: alice@example.com or 090-1234-5678.";
$output = $masker->process($input);

echo $output . PHP_EOL;
