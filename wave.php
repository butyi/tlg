<?php

// open file for reading in binary mode
$fp = fopen('wave.raw', 'rb');
if($fp===false)exit(1);

$txt="        db      ";
$col=0;
$bytecnt=0;
while(1){
  // read the entire file into a binary string
  $byte = ord(fread($fp, 1))&0xFF;
  if(feof($fp)){
    break;
  }
  if($byte==0)$byte=1;
  if($byte==255)$byte=254;
  printbyte($byte);
  $bytecnt++;
}
$i=5700;
while($i--){// 700ms silence before start next crime
  printbyte(0x80);
}
printbyte(0);// Mark end of waveform
$txt=substr($txt,0,-1).PHP_EOL;

// finally close the file
fclose($fp);

file_put_contents("wave.asm",$txt);
echo "$bytecnt bytes were printed.\n";

function printbyte($val){
  global $col, $txt;
  $txt.="$".sprintf("%02X",$val);
  $col++;
  if($col==16){
    $txt.=PHP_EOL."        db      ";
    $col=0;
  } else {
    $txt.=",";
  }
}


?>
