<?php
if (isset($_REQUEST["pattern"]) && isset($_REQUEST["persons"])){
	
	if(isset($_REQUEST["swap"])) {
		$swaplist = $_REQUEST["swap"];
	}else{
		$swaplist = "[]";
	}
	
	$plquery  = "swipl -q "
	          . "-f " . dirname($_SERVER["SCRIPT_FILENAME"]) . "/pl/siteswap.pl "
	          . "-g \"jp_pattern_def("
	          . $_REQUEST["pattern"] . ", "
	          . $_REQUEST["persons"] . ", "
			  . $swaplist
	          . "), halt.\"";
	
	if(isset($_REQUEST["download"]) && isset($_REQUEST["file"])) {
    	header("Content-type: application/force-download");
    	header("Content-Transfer-Encoding: Binary");
    	header("Content-disposition: attachment; filename=\"".$_REQUEST["persons"]."_".$_REQUEST["file"].".pass\"");
		echo `$plquery`;
	} else {		
?><!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>PrechacThis - JoePass</title>
	<link rel="shortcut icon" href="./images/favicon.png">
	<link rel="stylesheet" type="text/css" href="./css/prechacthis.css">
</head>
<body>
<?php
		if(isset($_REQUEST["debug"])) {
			echo "<pre>". $plquery ."</pre>";
		}
?>
	<pre><?php echo `$plquery`; ?></pre>
	<br>
	<br>
<?php echo "<a href=\"./joepass.php?download=on&". $_SERVER["QUERY_STRING"] ."\">download</a>"; ?>
<?php if(isset($_SERVER["HTTP_REFERER"])) {echo "&nbsp;|&nbsp;<a href=\"". $_SERVER["HTTP_REFERER"] ."\">back</a>";} ?>

</body>
</html>	
	
<?php
	}
} else {
	echo "something is wrong :-(";
}
?>