import processing.serial.*;

// 核心配置：串口+全屏参数
Serial myPort;
String portName = "/dev/cu.usbmodem11101"; // 替换为你的Arduino端口
int baudRate = 9600;
boolean serialConnected = false;
boolean isFullScreen = false; // 全屏状态标记

// 状态变量（与Arduino同步，记忆模块已修改）
int memState = 0;          // 0=Init→1=Select→2=Save→3=Tamper→4=WaitRecover→5=Recover→6=Fail→7=Reset
int selectedMem = 0;       // 记忆索引(0=Album 1=Music 2=Commute)
int charIndex = 0;         // 替换进度索引
int currentReplaceStart = 0;// 替换起始位
boolean syncState = false; // 同步闪烁状态
int recoverProgress = 0;   // 恢复进度(ms)
boolean isTamperComplete = false; // 篡改完成标记

// 核心修改：记忆数据替换为「相册」「音乐」「通勤」，文字为英文
String[] realMem = {"Album-NatureView", "Music-IndieDemo", "Commute-Alley"};    // 真实记忆
String[] fakeMem = {"Album-ViralSpot", "Music-PopHit", "Commute-NavApp"};       // 篡改记忆
String[] memTitles = {"Album Memory", "Music Memory", "Daily Commute"};         // 显示标题
int[] replaceStart = {6, 6, 8}; // 替换起始位（与Arduino一致）

// 视觉核心：粒子+窗帘+插画（插画增强：加深颜色、丰富细节、增加数量）
ArrayList<Particle> particles;
ArrayList<CurtainLayer> curtains;
ArrayList<IllustrateElement> illusElements; // 插画元素列表
// 记忆对应颜色：加深饱和度，提高辨识度
color[] memoryColors = {color(60, 180, 120), color(150, 120, 220), color(150, 150, 170)};
color standardColor = color(80, 160, 220);
color failColor = color(255, 60, 60);

// 粒子类（逻辑不变，颜色随记忆类型同步）
class Particle {
  PVector pos;
  PVector target;
  color col;
  float size;
  float speed;
  
  Particle(float x, float y, color c) {
    pos = new PVector(x, y);
    target = new PVector(x, y);
    col = c;
    size = random(6, 12);
    speed = random(0.005, 0.02);
  }
  
  void update(int state, float progress) {
    switch(state) {
      case 1: // 选记忆：聚集
        target = new PVector(width/2, height/2);
        pos.lerp(target, speed * 1.5);
        size = lerp(size, 12, 0.01);
        break;
      case 3: // 篡改中：网格排列+形态变化
        int gridCol = 20;
        int gridRow = 15;
        int index = particles.indexOf(this);
        int row = index / gridCol;
        int col = index % gridCol;
        target = new PVector(width/2 - (gridCol*25)/2 + col*25, height/2 - (gridRow*25)/2 + row*25);
        pos.lerp(target, speed * 2);
        size = lerp(12, 15, progress);
        break;
      case 5: // 恢复中：抖动+变色
        pos.x += random(-0.8, 0.8);
        pos.y += random(-0.8, 0.8);
        col = lerpColor(standardColor, failColor, progress);
        break;
      case 6: // 失败：扩散
        pos.x += random(-3, 3);
        pos.y += random(-3, 3);
        size = lerp(15, 5, progress);
        col = failColor;
        break;
      case 7: // 重置：随机分布
        target = new PVector(random(width*0.1, width*0.9), random(height*0.1, height*0.9));
        pos.lerp(target, speed);
        size = lerp(size, random(6, 12), 0.01);
        break;
      default:
        pos.lerp(target, speed);
        break;
    }
    pos.x = constrain(pos.x, 0, width);
    pos.y = constrain(pos.y, 0, height);
  }
  
  void display(int state, float progress) {
    noStroke();
    fill(col, 180);
    switch(state) {
      case 3: // 篡改中：圆→方过渡
        if (progress < 0.3) ellipse(pos.x, pos.y, size, size);
        else if (progress < 0.7) {
          rectMode(CENTER);
          rect(pos.x, pos.y, size, size, 10*(1-progress));
          rectMode(CORNER);
        } else {
          rectMode(CENTER);
          rect(pos.x, pos.y, size, size);
          rectMode(CORNER);
        }
        break;
      case 4: // 待恢复：闪烁方形
        rectMode(CENTER);
        fill(standardColor, syncState ? 220 : 80);
        rect(pos.x, pos.y, 15, 15);
        rectMode(CORNER);
        break;
      case 5: case 6: // 恢复/失败：方形
        rectMode(CENTER);
        rect(pos.x, pos.y, size, size);
        rectMode(CORNER);
        break;
      default: // 其他：圆形
        ellipse(pos.x, pos.y, size, size);
        break;
    }
  }
}

// 窗帘层类（逻辑不变）
class CurtainLayer {
  float x;
  float height;
  float opacity;
  float speed;
  
  CurtainLayer(float startX) {
    x = startX;
    this.height = random(height*0.8, height*1.2);
    opacity = random(30, 80);
    speed = random(0.2, 0.5);
  }
  
  void update(int state) {
    switch(state) {
      case 0: // 初始：移动
        x += speed;
        if (x > width + 50) x = -50;
        break;
      case 3: // 篡改：拉开+透明
        if (x < width/2) x -= speed * 1.5;
        else x += speed * 1.5;
        opacity = lerp(opacity, 10, 0.005);
        break;
      case 4: // 待恢复：闪烁
        opacity = lerp(opacity, syncState ? 40 : 10, 0.05);
        break;
      case 5: // 恢复：合拢+变浓
        if (x < width/2) x += speed;
        else x -= speed;
        opacity = lerp(opacity, 60, 0.005);
        break;
      case 6: // 失败：散开+透明
        x += x < width/2 ? -speed*3 : speed*3;
        opacity = lerp(opacity, 0, 0.01);
        break;
      case 7: // 重置：初始状态
        x = random(-50, width + 50);
        opacity = random(30, 80);
        break;
    }
  }
  
  void display() {
    noStroke();
    fill(255, 255, 255, opacity);
    rectMode(CENTER);
    rect(x, this.height/2, 20, this.height);
    rectMode(CORNER);
  }
}

// 核心修复：确保插画类型正确匹配（相册=照片，音乐=音符，通勤=公交/指南针）
class IllustrateElement {
  PVector pos;
  float size;
  float speed;
  int type; // 0=相册(图片) 1=音乐(音符) 2=通勤(公交/指南针)
  int subType; // 通勤子类型：0=公交 1=指南针
  
  IllustrateElement(int memType) {
    type = memType; // 关键：传入的记忆类型直接赋值给插画类型
    pos = new PVector(random(width), random(height));
    size = random(15, 40); // 放大尺寸，提高可见性
    speed = random(0.1, 0.3);
    // 通勤子类型随机分配
    if (type == 2) subType = int(random(2));
  }
  
  void update() {
    switch(type) {
      case 0: // 相册-图片：缓慢旋转+轻微浮动（模拟翻照片）
        pos.rotate(radians(speed * 0.5));
        pos.y += sin(millis() * 0.001) * speed;
        // 边界反弹，避免移出屏幕
        if (pos.x < 0 || pos.x > width) speed *= -0.8;
        if (pos.y < 0 || pos.y > height) speed *= -0.8;
        break;
      case 1: // 音乐-音符：上下跳动+左右移动（模拟音乐节奏）
        pos.y += sin(millis() * 0.002) * speed * 3; // 加大跳动幅度
        pos.x += speed * 0.8;
        if (pos.x > width + size) pos.x = -size;
        break;
      case 2: // 通勤-公交/指南针：随机移动+轻微旋转
        pos.x += random(-speed, speed);
        pos.y += random(-speed, speed);
        pos.rotate(radians(speed * 0.3));
        // 边界约束
        pos.x = constrain(pos.x, size, width - size);
        pos.y = constrain(pos.y, size, height - size);
        break;
    }
  }
  
  void display() {
    switch(type) {
      case 0: // 相册-图片：三层结构（外框+内框+内容）
        pushMatrix();
        translate(pos.x, pos.y);
        rectMode(CENTER);
        // 1. 外边框（深色粗边框）
        stroke(memoryColors[type], 200);
        strokeWeight(3);
        fill(245, 245, 245, 180); // 内页底色
        rect(0, 0, size*1.6, size*1.2, 2);
        // 2. 内边框（浅色细边框）
        stroke(memoryColors[type], 150);
        strokeWeight(1);
        fill(lerpColor(memoryColors[type], color(255), 0.7), 150); // 内容区颜色
        rect(0, 0, size*1.4, size*1.0, 1);
        // 3. 图片简化内容（中心图标：风景/人物示意）
        noStroke();
        fill(memoryColors[type], 120);
        if (size > 25) { // 大尺寸图片加细节
          ellipse(0, -size*0.1, size*0.3, size*0.2); // 太阳
          rect(0, size*0.1, size*0.8, size*0.3); // 地面
        }
        popMatrix();
        break;
      case 1: // 音乐-音符：加粗线条+填充，加深颜色
        pushMatrix();
        translate(pos.x, pos.y);
        stroke(memoryColors[type], 200); // 加深线条颜色
        strokeWeight(3); // 加粗线条
        fill(memoryColors[type], 150); // 填充色，提高立体感
        // 音符符头（圆形填充）
        ellipse(0, 0, size*0.6, size*0.6);
        // 音符符干（加粗）
        line(0, -size*0.3, 0, -size*1.5);
        // 音符符尾（加粗）
        line(0, -size*1.5, size*1.2, -size*1.1);
        // 符尾装饰（小短线）
        line(size*1.2, -size*1.1, size*1.2, -size*0.9);
        popMatrix();
        break;
      case 2: // 通勤-公交/指南针：清晰图标
        pushMatrix();
        translate(pos.x, pos.y);
        stroke(memoryColors[type], 200);
        strokeWeight(2);
        fill(memoryColors[type], 120);
        rectMode(CENTER);
        
        if (subType == 0) { // 公交图标
          // 车身
          rect(0, 0, size*1.2, size*0.8);
          // 车窗（两个矩形）
          fill(220, 240, 255, 180);
          rect(-size*0.3, -size*0.1, size*0.4, size*0.3);
          rect(size*0.3, -size*0.1, size*0.4, size*0.3);
          // 车轮（两个圆形）
          fill(80, 80, 80, 180);
          ellipse(-size*0.4, size*0.4, size*0.2, size*0.2);
          ellipse(size*0.4, size*0.4, size*0.2, size*0.2);
        } else { // 指南针图标
          // 外圆
          ellipse(0, 0, size*1.2, size*1.2);
          // 指针（南北）
          strokeWeight(3);
          line(0, -size*0.5, 0, size*0.5);
          // 指针（东西）
          line(-size*0.5, 0, size*0.5, 0);
          // 指向标（N/S）
          noStroke();
          textSize(size*0.2);
          fill(0, 180);
          text("N", 0, -size*0.4);
          text("S", 0, size*0.6);
        }
        popMatrix();
        break;
    }
  }
}

void setup() {
  fullScreen(); // 自适应全屏（MacBook Pro 14英寸适配）
  smooth(8);
  // 初始化视觉元素（仅粒子和窗帘，初始状态不初始化插画）
  particles = new ArrayList<Particle>();
  curtains = new ArrayList<CurtainLayer>();
  illusElements = new ArrayList<IllustrateElement>(); // 仅创建列表，不添加元素
  initBasicVisuals(); // 初始化粒子和窗帘
  // 串口连接
  connectSerial();
  println("Init Complete: " + (serialConnected ? "Serial Connected" : "Local Debug"));
}

void draw() {
  // 渐变背景
  setGradientBackground();
  // 串口读取（同步Arduino状态）
  if (serialConnected) readSerialData();
  // 进度计算
  float tamperProgress = getTamperProgress();
  float recoverProgressNorm = map(recoverProgress, 0, 6000, 0, 1);
  // 绘制层级：仅非初始状态（memState≠0）绘制插画
  if (memState != 0) {
    updateAndDisplayIllustrate();
  }
  updateAndDisplayCurtains();
  updateAndDisplayParticles(tamperProgress, recoverProgressNorm);
  drawStateText(tamperProgress, recoverProgressNorm);
  if (memState == 5) drawRecoveryBar(recoverProgressNorm);
  // 全屏控制
  checkFullScreen();
  // 本地调试（无串口时用键盘控制）
  if (!serialConnected) localDebugControl();
  // 状态流转
  autoStateTransition();
}

// 初始化基础视觉元素（仅粒子和窗帘，不含插画）
void initBasicVisuals() {
  particles.clear();
  // 初始状态粒子用标准色，进入选择状态后同步记忆颜色
  for (int i = 0; i < 400; i++) {
    particles.add(new Particle(random(width*0.1, width*0.9), random(height*0.1, height*0.9), standardColor));
  }
  curtains.clear();
  for (int i = 0; i < 15; i++) {
    curtains.add(new CurtainLayer(random(-50, width + 50)));
  }
}

// 初始化插画元素（根据当前选择的记忆类型创建对应插画）
void initIllustrations() {
  illusElements.clear();
  // 批量创建对应类型的插画（50个确保密度）
  for (int i = 0; i < 50; i++) {
    illusElements.add(new IllustrateElement(selectedMem)); // 关键：传入selectedMem确保类型匹配
  }
  // 同步粒子颜色为当前记忆颜色
  for (Particle p : particles) {
    p.col = memoryColors[selectedMem];
  }
}

// 串口连接（逻辑不变）
void connectSerial() {
  try {
    if (myPort != null) myPort.stop();
    myPort = new Serial(this, portName, baudRate);
    myPort.bufferUntil('\n');
    serialConnected = true;
  } catch (Exception e) {
    serialConnected = false;
    println("Serial Error: " + e.getMessage());
  }
}

// 串口读取（同步状态+修复插画类型初始化）
void readSerialData() {
  while (myPort.available() > 0) {
    String data = myPort.readStringUntil('\n');
    if (data != null && data.length() > 0) {
      data = trim(data);
      String[] vals = split(data, ',');
      if (vals.length == 6) {
        try {
          int newMemState = int(vals[0]);
          int newSelectedMem = int(vals[1]);
          // 状态从0切换到1（初始→选择），或记忆类型变化时，重新初始化插画
          if ((newMemState == 1 && memState != 1) || (newSelectedMem != selectedMem)) {
            selectedMem = newSelectedMem;
            initIllustrations(); // 重新初始化对应类型插画
          }
          // 更新所有状态变量
          memState = newMemState;
          selectedMem = newSelectedMem;
          charIndex = int(vals[2]);
          currentReplaceStart = int(vals[3]);
          syncState = vals[4].equals("1");
          recoverProgress = int(vals[5]);
          isTamperComplete = (charIndex >= fakeMem[selectedMem].length());
        } catch (Exception e) {
          println("Parse Error: " + data);
        }
      }
    }
  }
}

// 插画元素更新和绘制（逻辑不变）
void updateAndDisplayIllustrate() {
  for (IllustrateElement ie : illusElements) {
    ie.update();
    ie.display();
  }
}

// 渐变背景（逻辑不变）
void setGradientBackground() {
  color startCol, endCol;
  switch(memState) {
    case 0: case 1: startCol=color(255,245,230); endCol=color(255,235,210); break;
    case 2: startCol=color(230,240,255); endCol=color(220,235,255); break;
    case 3: startCol=color(200,220,240); endCol=color(180,210,250); break;
    case 4: startCol=color(160,190,230); endCol=color(140,180,220); break;
    case 5: startCol=color(255,200,200); endCol=color(255,190,190); break;
    case 6: startCol=color(255,160,160); endCol=color(255,140,140); break;
    default: startCol=color(255,245,230); endCol=color(255,235,210); break;
  }
  for (int y=0; y<height; y++) {
    float ratio = map(y, 0, height, 0, 1);
    stroke(lerpColor(startCol, endCol, ratio));
    line(0, y, width, y);
  }
}

// 窗帘绘制（逻辑不变）
void updateAndDisplayCurtains() {
  for (CurtainLayer c : curtains) {
    c.update(memState);
    c.display();
  }
}

// 粒子绘制（逻辑不变）
void updateAndDisplayParticles(float tamperProgress, float recoverProgressNorm) {
  for (Particle p : particles) {
    if (memState==3) p.update(memState, tamperProgress);
    else if (memState==5) p.update(memState, recoverProgressNorm);
    else if (memState==6) p.update(memState, tamperProgress);
    else p.update(memState, 0);
    
    if (memState==3) p.display(memState, tamperProgress);
    else if (memState==5) p.display(memState, recoverProgressNorm);
    else if (memState==6) p.display(memState, tamperProgress);
    else p.display(memState, 0);
  }
}

// 状态文本（显示修改后的记忆标题与内容）
void drawStateText(float tamperProgress, float recoverProgressNorm) {
  textFont(createFont("Helvetica", 32));
  textAlign(CENTER, CENTER);
  fill(0, 200);
  String mainText = "", subText = "";
  switch(memState) {
    case 0: mainText="Press Joystick to Start"; subText="Memory Colonization Simulation"; break;
    case 1: mainText="Select Memory: "+memTitles[selectedMem]; subText="Joystick Left/Right | Press to Confirm"; break;
    case 2: mainText="Saving Memory..."; subText=realMem[selectedMem]; break;
    case 3: mainText="Memory Tampering..."; subText=getCurrentMemoryText()+" | Progress: "+int(tamperProgress*100)+"%"; break;
    case 4: mainText="Press Joystick to Recover"; subText="Attempt to Restore Original Memory"; break;
    case 5: mainText="Recovering..."; subText="Remaining: "+(6-recoverProgress/1000)+"s | Progress: "+int(recoverProgressNorm*100)+"%"; break;
    case 6: mainText="Recovery Failed"; subText="Memory Standardized Permanently"; break;
    case 7: mainText="Press Joystick to Restart"; subText="Memory Colonization Simulation"; break;
  }
  float mainSize = map(width, 1280, 2560, 48, 72);
  float subSize = map(width, 1280, 2560, 24, 36);
  textSize(mainSize);
  text(mainText, width/2, height/2-80);
  textSize(subSize);
  text(subText, width/2, height/2+40);
}

// 进度条（逻辑不变）
void drawRecoveryBar(float progress) {
  float barW = map(width, 1280, 2560, width*0.6, width*0.7);
  float barH = map(height, 720, 1440, 30, 50);
  float x = (width-barW)/2, y=height*0.75;
  // 背景条
  noFill();
  strokeWeight(8);
  stroke(failColor, 150);
  rect(x, y, barW, barH, 10);
  // 进度条
  fill(failColor, 220);
  noStroke();
  rect(x, y, barW*progress, barH, 10);
}

// 全屏控制（逻辑不变）
void checkFullScreen() {
  if (keyPressed && key == ESC) {
    if (isFullScreen) {
      isFullScreen = false;
      println("Exited Full Screen");
    }
    key = 0;
  }
}

// 本地调试（修复插画初始化逻辑）
void localDebugControl() {
  if (keyPressed) {
    // 切换记忆：确保切换时重新初始化对应插画
    if (keyCode==LEFT && selectedMem>0 && memState==1) {
      selectedMem--;
      currentReplaceStart=replaceStart[selectedMem];
      initIllustrations(); // 切换记忆类型，重新初始化插画
      delay(300);
    }
    if (keyCode==RIGHT && selectedMem<2 && memState==1) {
      selectedMem++;
      currentReplaceStart=replaceStart[selectedMem];
      initIllustrations(); // 切换记忆类型，重新初始化插画
      delay(300);
    }
    // 状态切换：从初始(0)到选择(1)时初始化插画
    if (key==' ' && memState==0) {
      memState=1;
      initIllustrations(); // 进入选择状态，初始化对应插画
      delay(200);
    }
    else if (key==' ' && memState==1) {
      memState=2; delay(1500); memState=3; charIndex=currentReplaceStart; delay(200);
    } else if (key==' ' && memState==4) {
      memState=5; recoverProgress=0; delay(200);
    } else if (key==' ' && memState==6) {
      memState=7; delay(1500); resetAllStates(); delay(200);
    } else if (key==' ' && memState==7) {
      memState=0; delay(200);
    }
    // 切换全屏
    if ((key=='f'||key=='F')) {
      isFullScreen = !isFullScreen;
      key=0; delay(200);
    }
  }
  // 自动推进进度
  if (memState==3 && frameCount%8==0) {
    charIndex++;
    isTamperComplete=(charIndex>=fakeMem[selectedMem].length());
    if (isTamperComplete) {memState=4;}
  }
  if (memState==5) {
    recoverProgress+=80;
    if (recoverProgress>6000) {memState=6;}
  }
}

// 状态自动流转（逻辑不变）
void autoStateTransition() {
  if (memState==3 && isTamperComplete && !serialConnected) {
    memState=4; isTamperComplete=false;
  }
  if (memState==5 && recoverProgress>=6000 && !serialConnected) {
    memState=6;
  }
}

// 篡改进度计算（逻辑不变）
float getTamperProgress() {
  int totalLen = fakeMem[selectedMem].length() - currentReplaceStart;
  return totalLen<=0 ? 0 : constrain((charIndex-currentReplaceStart)/(float)totalLen,0,1);
}

// 记忆文本获取（逻辑不变，显示修改后的记忆内容）
String getCurrentMemoryText() {
  String showMem = realMem[selectedMem].substring(0, currentReplaceStart);
  showMem += fakeMem[selectedMem].substring(currentReplaceStart, min(charIndex, fakeMem[selectedMem].length()));
  if (charIndex < realMem[selectedMem].length()) showMem += realMem[selectedMem].substring(charIndex);
  return showMem.length()>35 ? showMem.substring(0,35)+"..." : showMem;
}

// 状态重置（恢复初始无插画状态）
void resetAllStates() {
  memState=0; selectedMem=0; charIndex=0; currentReplaceStart=0; recoverProgress=0; isTamperComplete=false;
  initBasicVisuals(); // 重置粒子和窗帘
  illusElements.clear(); // 清空插画，回到初始无插画状态
}

// 资源释放（逻辑不变）
void exit() {
  if (myPort!=null) myPort.stop();
  super.exit();
}
