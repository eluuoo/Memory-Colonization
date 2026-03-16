Memory Colonization

By  Yilu Tan

video link ：https://youtu.be/JWsbSuam0Pk
github link ：https://github.com/eluuoo/Memory-Colonization

Introduction

This project employs Arduino and Processing to transform the intangible phenomenon of ‘algorithms subtly manipulating memory’ into a tangible, physical interactive installation. Users select personal recollections—such as music, travel, or commuting—via a joystick, witnessing firsthand how warm, authentic memories (represented by yellow lights) are progressively overwritten by cold, algorithmic content (blue lights). Attempts to restore the original memories prove futile due to technical resistance (red lights) and never success. Through an intuitive sensory experience, the installation exposes the essence of how ‘in the digital age, memory has been reduced from a private spiritual asset to technologically controllable data,’ prompting reflection on whether ‘digital devices preserve or alter memory.’


Equipment List

Installation overview (Arduino LCD + three colour LED lights + left potentiometer for adjusting LCD screen brightness + right joystick button, full-screen Processing visual interface on computer, built-in passive buzzer)
![IMG_1770](https://github.com/user-attachments/assets/3ea7c51e-664b-47d1-acee-96f25e4433a6)

- Core Control: Arduino (manages joystick input, LCD text display, LED lighting effects, and serial communication with Processing) 
- Interactive Input: Analogue joystick for left/right memory selection, press to confirm operation, and final trigger for restoration
- Adjustment Component: 10k Potentiometer for manually rotating to adjust LCD display text brightness, adapting to visual requirements of different exhibition environments
- Output Devices: 3 LEDs (yellow/blue/red indicating memory states), LCD display screen (showing gradient memory text), Processing display screen, buzzer (providing synchronised audio feedback with LED states) 
<img width="1176" height="768" alt="Screenshot 2025-12-09 at 11 35 19" src="https://github.com/user-attachments/assets/7c432dc1-6941-4ca2-95d5-3ab82ced77f1" />


![pc](https://github.com/user-attachments/assets/7f35f1d1-6be1-462f-8a2e-2430fa5d09ac)



How to Run the Project
1. First, connect the Arduino code to the devices inside the installation, and then open the processing code to display the animation on the computer screen.

2. Press the joystick to enter the selection. Use the joystick to switch between the three memories: music, travel, and commuting. 

3. For example, if you select the travel memory, the yellow light meaning the real memory will light up, and the small screen will display "Commute-Alley", while the large screen will show  illustration. 

4. Press the  joystick to confirm and the alteration will take place: the blue light starts flashing and brightens up, the yellow light gradually dims, and on the small screen, "Alley" gradually changes to "NavApp". The particles in the picture also change from circular to square ( this is like the algorithm cover up our private memories.)

5.  Next comes the recovery stage: When you try to restore again, the red light will gradually come on, and there will be an alarm sound. As the progress bar moves forward, it eventually shows "Recovery Failed". (It likes our memories stored in the cloud. They have already lost their ownership, and even the recovery process is subject to technical limitations.)
<img width="1066" height="797" alt="截屏2025-12-10 09 41 44" src="https://github.com/user-attachments/assets/19fb15f6-fa04-47cf-91cf-d68e5107cad5" />




Display

![IMG_1761](https://github.com/user-attachments/assets/b32546de-742a-404f-9c74-9973d84d3622)
![IMG_1784](https://github.com/user-attachments/assets/c9c9c3cf-5923-4d22-ae97-3c85ee34eabf)
![IMG_8712](https://github.com/user-attachments/assets/d3c24d7d-e78d-4514-a9b9-38482bd453ab)



References


Adorno, T.W. & Horkheimer, M. (2002). Dialectic of Enlightenment. Stanford University Press.

Han, B. (2017). The Burnout Society. Stanford University Press.

Doidge, N. (2007). The Brain That Changes Itself. Penguin Books.

Sontag, S. (2001). On Photography (1st Picador USA ed.). Picador USA.
 
Arduino. (2023). LiquidCrystal - scrollDisplayRight() [Online documentation]. Arduino Official Website. Available from: https://www.arduino.cc/reference/en/libraries/liquidcrystal/scrolldisplayright/ 
