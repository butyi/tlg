# heater_pwm

Team Leave Gift gadget

## Introduction

Once my colleague leave our team who worked a lot with Ford vehicles.
We wanted to give him some present by which he will remember our team and his work here.
Idea of team member Kristóf was to give a box with a small MP3 player board with battery and
a button, which can play Ford warning chime.

Fact, that I developed and produced a small UART to CAN converter box - called
[sci2can](https://github.com/butyi/sci2can)
- which we are using often in our team during daily job.
My idea was to try to play the warning chime with this converter box.
This would be better because both hardware and chime voice are memory for him.

## Meditation

The
[chime](https://www.youtube.com/watch?v=2mYmA-hSiaID)
sound is simple, it has no high frequency components, so 8000kHz sample speed should be enough.
This means sample changer software code must be executed 8000 times in a second. This is easy,
because bus frequency can be 20MHz max, much faster than needed.
Since MC9S08DZ60 has no built-in DAC module, my first idea was to use
a 8bits resisitor ladder on 8 bit wide PTE port.

## Let's try

I have started trial on my 48pin socket Uc trial board
![trialboard](https://github.com/butyi/sci2can/raw/master/pics/demo9s08dz60.jpg)

I have created the resistor ladder on this board
![trialboard](https://github.com/butyi/sci2can/raw/master/pics/demo9s08dz60.jpg)

To have the chime waveform in software I had
- Downloaded the chime by [youtube-dl](https://youtube-dl.org/)
- Cut a single warning (~1s long) from that by [Audacity](https://www.audacityteam.org/)
- Merged stereo channels into mono channel
- Normalized the amplitude and additionally amplified a bit more to be more lauder even if with distorsion.
- Downsampled to 8kHz sample frequency (Left bottom corner "Project Rate (Hz)" on main form of Audacity)
- Saved as unsigned 8bit sample size waveform without header (I have selected RAW file format in Export menu)
- Converted samples into assembly source code format by a PHP script by `wave.php`
- Compile into the software

Trial software was a simple easy assembly code, timed by NOP-loop.

Fortunately I had small 8 Ohm speaker from a damaged tablet and I had found.

Trial was successful, with a single transistor as emitter follower
at the end of resistor ladder, the speaker produced quiet but recognisable voice.
Yess!

## 8 port pins are so much

My next idea was to omit resistor ladder, because on my [sci2can](https://github.com/butyi/sci2can) board not all pins of
PTE port is used, and solder on the microcontroller pin is not reliable against shaking.
8kHz is not so fast, if PWM could be faster, that should be tried.
With default internal clock I could reach 60kHz PWM frequency with 8 bit duty cycle resolution.
8 PWM periods for one sample can cause maximum ~12% error on sample level, this is acceptable.

## Drive the speaker 

The single transistor emitter follower is not sufficent because speaker has half supply voltage
DC component, what heats up the speaker (it will burn down the speaker after a while) and discharge the battery faster.
Speaker shall be driven without DC component. Serial large capacitor is not proper, because
it is charged up and there is nothing to charge down, so speaker is silent.
Two pole of speaker shall be driven in same PWM phrase but opposite voice waveform phrase.
In this case, when sample value is zero (unsigned $80), both speaker poles are either high or low logic level depends on the PWm signal state,
so difference is always zero. But when sample is non zero, once pole shall be so higher than the other pole lower.
For this I have prepared two half bridges. I had no FETs at home, only transistors, so I used transistors (4 x BC182).
Due to basis-emitter voltage (~0.6V) I loose some laudness, but life is hard.
Two half bridges are driven by two PWM channels. Since two channels share the same counter and modulo
register, same PWM phrase is ensured by hardware. Only sample value negation is needed in software between two channels.

Result is very good! Voice is more clear than with resistor ladder, it need less Uc pins, speaker driving
without DC component is also easy and need minimum number of hardware component.

## Greeting message

Half of sci2can boxes have 0.96 inch OLED display with 128x64 pixels. This is suitable to display some greeting messages.
Of course this is also needed for the perfect gift gadget.
Team idea was also to collect specific sentences and show one random way at each power on.
Finally we decided
- Change screen at each chime (1.7s or multiplies)
- Show team logo first
- Show specific message
- Show names of team members
- Show some general screen

## Picture

Since display pixels have no lightness, only on or off state, to display an image,
it shall be converted to black and white at a well defined treshold level
and resized down to display size (128 x 64 in my case). This is done by `picture.php`.

I had already written characters for graphic display which displays characters by IIC command byte series for each characters.
Therefore easiest way was to generate same IIC commands for eaxh 8 x 8 pixel image parts for eash parts.
This is also done `picture.php`.
Generated file with IIC commands shall be included and image can be printed on the display easily by calling DISP_image.

## Hardware

The hardware is [sci2can board](https://github.com/butyi/sci2can)
with 0.96 inch 128x64 OLED display with IIC interface.
CAN is not needed, 5V DC-DC step-down supply is used because finally I used A23 type 12V battery.
I have written the software to use internal clock, so external resonator (Quarz) not needed.
For hardware switch off, button is connected serial with supply battery.

![board](https://github.com/butyi/tlg/blob/main/board.jpg)

Additionally needed the two half-bridge and speaker.

![bridges](https://github.com/butyi/tlg/blob/main/bridges.jpg)
![speaker](https://github.com/butyi/tlg/blob/main/speaker.jpg)

## Software

Software is pure assembly code. Only tne necessary code is written.

To understand my description below you may need to look at the related part in
[processor reference manual](https://www.nxp.com/docs/en/data-sheet/MC9S08DZ60.pdf).

#### Central Processor Unit (S08CPUV3)
 
For understanding assembly commands read
[HCS08RMV1.pdf](https://github.com/butyi/sci2can/raw/master/hw/HCS08RMV1.pdf).

#### Multi-purpose Clock Generator (S08MCGV1)

MCG default configuration (internal clock) is not changed.
Only some small changes were done
- Speed up MCGOUT by disable divider
- Enable IRCLK for RTC module

#### Structure

Main background software only handles the display.
The sound is played from interrupt routine.

#### Initialization

Stack, ports, needed modules are initialized one by one first.

#### Main activity

The main activity is a sequnce of display update according to above screen contents.
After each display update a delay is executed till the next (or more) chime.

#### Main loop

Main loop only updates chime counter on display and sometime show some message instead of chime counter.

#### Interrupt routine

PWM channels are configured to 50% duty by default. The samples are changes by periodic 8kHz interrupt.
The inter chime silence is now part of waveform, since there is enough Flash memory
and no software intervention is needed for silence. Simple endless loop is implemented for the waveform.

### Compile

- Download assembler from [aspisys.com](http://www.aspisys.com/asm8.htm).
  It works on both Linux and Windows.
- Check out the repo
- Run my bash file `./c`.
  Or run `asm8 prg.asm` on Linux, `asm8.exe prg.asm` on Windows.
- prg.s19 is now ready to download.

### Download

I have used the cheap USBDM Hardware interface. I have bought it for 10€ on Ebay.
Just search "USBDM S08".

USBDM has free software tool support for S08 microcontrollers.
You can download it from [here](https://sourceforge.net/projects/usbdm/).
When you install the package, you will have Flash Downloader tools for several
target controllers. Once is for S08 family.

It is much more comfortable and faster to call the download from command line.
Just run my bash file `./p`.

## Further ideas

- Accent support for hungarian letters
- Write chime counter in EEPROM to see all number of played chimes
- Low power mode usage and button to be connected to interrupt input

## License

This is free. You can do anything you want with it.
While I am using Linux, I got so many support from free projects,
I am happy if I can give something back to the community.

## Keywords

Car, Fan, Heater, PWM, PulseWidthModulation, Waveform, Audio, Player
Motorola, Freescale, NXP, MC68HC9S08DZ60, 68HC9S08DZ60, HC9S08DZ60, MC9S08DZ60,
9S08DZ60, HC9S08DZ48, HC9S08DZ32, HC9S08DZ, 9S08DZ, UART, RS232.

###### 2022 Janos BENCSIK


