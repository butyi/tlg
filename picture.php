<?php

if($argc<2){
  echo "ERROR! Missing input image file.".PHP_EOL;
  echo "---------- picture.php ----------".PHP_EOL;
  echo "Resize image to target display size,".PHP_EOL;
  echo "convert to monocrome (not grayscale!),".PHP_EOL;
  echo "save a png to see the result and".PHP_EOL;
  echo "generate IIC display commands".PHP_EOL;
  echo "to show image on 0.96 inch 128x64 pixels OLED display.".PHP_EOL;
  echo "".PHP_EOL;
  echo "Call: php picture.php input_image_file [width_in_pixel] [height_in_pixel] [left_in_pixel] [top_in_pixel]".PHP_EOL;
  echo "Examples:".PHP_EOL;
  echo "php picture.php logo.png -> Convert logo.png to 128x64 (full size) display image.".PHP_EOL;
  echo "php picture.php logo.png 64 -> Convert logo.png to 64x64 display image.".PHP_EOL;
  echo "php picture.php logo.png 64 32 -> Convert logo.png to 64x32 display image.".PHP_EOL;
  echo "php picture.php logo.png 64 32 32 -> Convert logo.png to 64x32 display image with 32 pixels X offset.".PHP_EOL;
  echo "php picture.php logo.png 64 32 32 16 -> Convert logo.png to 64x32 display image with 32 pixels X and 16 pixels Y offset.".PHP_EOL;
  echo "".PHP_EOL;
  echo "Pixels shall be multiplication of 8 pixels (size of 1 character)".PHP_EOL;
  exit;
}
$file = $argv[1];
if(!file_exists($file)){
  echo "ERROR! Cannot open input image file.".PHP_EOL;
  exit;
}

if(2<$argc){
  $width = intval($argv[2]);
} else {
  $width = 128;
}
if($width<8){
  echo "ERROR! Too small target width. At least one character (8 pixels) expected.".PHP_EOL;
  exit;
}
if($width%8){
  echo "ERROR! Image must be sized to complete characters.".PHP_EOL;
  exit;
}
if(3<$argc){
  $height = intval($argv[3]);
} else {
  $height = 64;
}
if($height<8){
  echo "ERROR! Too small target height. At least one character (8 pixels) expected.".PHP_EOL;
  exit;
}
if($height%8){
  echo "ERROR! Image must be sized to complete characters.".PHP_EOL;
  exit;
}

if(4<$argc){
  $left = intval($argv[4]);
} else {
  $left = 0;
}
if((128-8)<$left){
  echo "ERROR! Too large left offset.".PHP_EOL;
  exit;
}
if(5<$argc){
  $top = intval($argv[5]);
} else {
  $top = 0;
}
if((64-8)<$top){
  echo "ERROR! Too large top offset.".PHP_EOL;
  exit;
}


$src = imagecreatefrompng($file);
list($srcwidth, $srcheight) = getimagesize($file);
$dst = imagecreatetruecolor($width, $height);
imagecopyresampled($dst, $src, 0, 0, 0, 0, $width, $height, $srcwidth, $srcheight);

$black = imageColorAllocate($dst, 255, 255, 255);
$white = imageColorAllocate($dst, 0, 0, 0);

for($x=0;$x<$width;$x++){
  for($y=0;$y<$height;$y++){
    $rgb = imagecolorat($dst, $x, $y);
    $r = ($rgb >> 16) & 0xFF;
    $g = ($rgb >> 8) & 0xFF;
    $b = $rgb & 0xFF;
    $gray = ($r + $g + $b) / 3;
    if($gray < 220){
      $rgb = $black;
    } else {
      $rgb = $white;
    }
    imagesetpixel($dst, $x, $y, $rgb);
  }
}

$path_parts = pathinfo($file);
$file = $path_parts['filename'];
//imagepng($dst,$file.".png");

$code = "; -----------------------------------------------------------
; Assambly picture definitions. Generated from picture.php
; These are already in I2C command format.
; -----------------------------------------------------------
#ROM

$file
        ;       Character position (High nibble is Y from 0 to 7, low nibble is X from 0 to 15)
        ;       |   Command of action (Write 9 bytes to IIC)
        ;       |   |   Co=0 (continuous), D/C#=1 (next bytes are data)
        ;       |   |   |   First (most left) column of character
        ;       |   |   |   |   Last (most right) column of character
        ;       |   |   |   |   +-----------------------+   End of action
        ;       |   |   |   |     (LSB:Top MSB:bottom)  |   |
";

for($r=0;$r<($height/8);$r++){
  for($c=0;$c<($width/8);$c++){

    $code .= "        db      \$".sprintf("%X%X",$r+($top/8),$c+($left/8)).",\$09,\$40";
    for($x=0;$x<8;$x++){
      $byte = 0;
      for($y=0;$y<8;$y++){
        $rgb = imagecolorat($dst, ($c*8)+$x, ($r*8)+$y);
        $rgb = (0 == $rgb);
        if(!$rgb){
          $byte |= (1<<$y);
        }
      }
      $code .= ",\$".sprintf("%02X",$byte);
    }
    $code .= ",\$00 ; Row $r, Column $c".PHP_EOL;

  }
}

$code .= "        db      \$FF     ; End of picture".PHP_EOL;

file_put_contents($file.".inc",$code);
imagedestroy($dst);

?>
