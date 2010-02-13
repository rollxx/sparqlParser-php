<?php
ini_set('error_reporting', E_ALL | E_STRICT);
//set_include_path(get_include_path() . PATH_SEPARATOR . dirname(__FILE__));
set_include_path(get_include_path() . PATH_SEPARATOR . '/Applications/MAMP/htdocs/rollxx-sparql2-parser/erfurt/src/');
set_include_path(get_include_path() . PATH_SEPARATOR . '/Applications/MAMP/htdocs/rollxx-sparql2-parser/ontowiki/src/libraries/');
// ini_set("memory_limit","1G");
$time_start = microtime(true);
require_once '/Users/roll/Downloads/antlrphpruntime-read-only/runtime/Php/antlr.php';
require_once 'Erfurt_Sparql_Sparql10Lexer.php';
require_once 'Erfurt_Sparql_Sparql10_Tokens.php';
require_once 'Erfurt_Sparql_Sparql10Parser.php';
$include_time_end = microtime(true);

$new_time_start = microtime(true);

// #
// # usage: php runsparql.php
// #
// 
// $input = new ANTLRFileStream(dirname(__FILE__).DIRECTORY_SEPARATOR.$argv[1]);

$input = new ANTLRFileStream(dirname(__FILE__).DIRECTORY_SEPARATOR."input");
$lexer = new Erfurt_Sparql_Sparql10Lexer($input);
// $lexer = new CommonLexer($input);
$tokens = new CommonTokenStream($lexer);

//foreach ($tokens->getTokens() as $t) {
//		echo $t."\n";
//}

$parser = new Erfurt_Sparql_Sparql10Parser($tokens);
$q = $parser->start();
var_dump($q->getSparql());
$time_end = microtime(true);
$time = $time_end - $time_start;

echo "\nincluding files time : " . ($include_time_end - $time_start) .PHP_EOL;
echo "parsing time : " . (microtime(true) - $new_time_start) .PHP_EOL;

?>
