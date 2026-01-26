#include <LiquidCrystal.h>
// 引脚定义（原接线不变）
const int rs = 12, en = 11, d4 = 5, d5 = 4, d6 = 3, d7 = 2;
#define JOY_X A1        // 摇杆X轴
#define JOY_SW 7        // 摇杆按键
#define BUZZER 6        // 蜂鸣器
#define LED_YELLOW 10   // 黄灯（真实）
#define LED_BLUE 13     // 蓝灯（篡改）
#define LED_RED 9       // 红灯（警告）

// 初始化LCD对象
LiquidCrystal lcd(rs, en, d4, d5, d6, d7);

// 记忆文本定义
String realMem[3] = {"Album-NatureView", "Music-NicheDemo", "Commute-Alley"};
String fakeMem[3] = {"Album-ViralSpot", "Music-PopHit", "Commute-NavApp"};

// 状态变量
int memState = 0;      // 0=初始→1=选记忆→2=确认→3=篡改→4=待恢复→5=恢复→6=失败
int selectedMem = 0;   // 选中记忆索引
int charIndex = 0;     // 渐变字符索引
unsigned long syncInterval = 800; // 同步周期（800ms）
unsigned long lastSyncTime = 0;
bool syncState = false; // 同步状态（亮/灭）
int replaceStart[3] = {6, 6, 8};  // 替换起始位
int currentReplaceStart = 0;      // 当前选中记忆的替换起始位
unsigned long recoverProgress = 0; // 恢复进度
unsigned long lastSendTime = 0;    // 串口发送频率控制

// 函数声明（解决未定义警告）
void selectMemoryByJoy(int joyXValue);

void setup() {
  // 初始化串口
  Serial.begin(9600);
  
  // 初始化引脚模式
  pinMode(JOY_SW, INPUT_PULLUP);
  pinMode(BUZZER, OUTPUT);
  pinMode(LED_YELLOW, OUTPUT);
  pinMode(LED_BLUE, OUTPUT);
  pinMode(LED_RED, OUTPUT);
  
  // 初始化LCD
  lcd.begin(16, 2);
  lcd.print("Press Button to");
  lcd.setCursor(0, 1);
  lcd.print(" Start Select !");
  analogWrite(LED_YELLOW, 255); // 初始黄灯常亮
}

void loop() {
  int joyX = analogRead(JOY_X);
  int joyPress = digitalRead(JOY_SW);

  // 状态0：初始界面
  if (memState == 0) {
    if (joyPress == LOW) { 
      while(digitalRead(JOY_SW) == LOW) delay(10); // 防抖
      lcd.clear();
      lcd.print("Select Memory:");
      lcd.setCursor(0, 1);
      lcd.print(realMem[selectedMem].substring(0,15));
      currentReplaceStart = replaceStart[selectedMem];
      memState = 1;
    }
  }

  // 状态1：选记忆界面
  else if (memState == 1) {
    selectMemoryByJoy(joyX); 
    if (joyPress == LOW) { 
      while(digitalRead(JOY_SW) == LOW) delay(10); 
      lcd.clear();
      lcd.print("Saving Memory");
      lcd.setCursor(0, 1);
      lcd.print(realMem[selectedMem].substring(0,15));
      tone(BUZZER, 500, 800); 
      delay(1500);
      charIndex = currentReplaceStart;
      lastSyncTime = millis();
      syncState = false;
      memState = 2; 
    }
  }

  // 状态2：确认录入
  else if (memState == 2) {
    analogWrite(LED_YELLOW, 255); 
    memState = 3; 
  }

  // 状态3：篡改中
  else if (memState == 3) {
    if (millis() - lastSyncTime > syncInterval) {
      lastSyncTime = millis();
      syncState = !syncState;

      // 蓝灯同步闪烁
      analogWrite(LED_BLUE, syncState ? 255 : 0);
      // 音频同步
      if(syncState) tone(BUZZER, 2000, 20); 
      else noTone(BUZZER);

      // 文本渐变替换
      lcd.clear();
      lcd.print("Changing...");
      lcd.setCursor(0, 1);
      String showMem = "";
      
      if (syncState && charIndex <= fakeMem[selectedMem].length()) {
        showMem = realMem[selectedMem].substring(0, currentReplaceStart);
        showMem += fakeMem[selectedMem].substring(currentReplaceStart, charIndex);
        if (charIndex < realMem[selectedMem].length()) {
          showMem += realMem[selectedMem].substring(charIndex);
        }
        charIndex++;
      } else {
        showMem = realMem[selectedMem];
      }
      
      lcd.print(showMem.substring(0,15) + " ");

      // 黄灯渐灭
      int totalReplaceLen = fakeMem[selectedMem].length() - currentReplaceStart;
      int progress = map(charIndex - currentReplaceStart, 0, totalReplaceLen, 0, 255);
      int yellowBright = 255 - progress;
      if(yellowBright < 0) yellowBright = 0;
      analogWrite(LED_YELLOW, yellowBright);

      // 篡改完成
      if (charIndex >= fakeMem[selectedMem].length()) {
        analogWrite(LED_BLUE, 255);
        noTone(BUZZER);
        analogWrite(LED_YELLOW, 0); 
        tone(BUZZER, 600, 300);
        memState = 4;
      }
    }
  }

  // 状态4：待恢复
  else if (memState == 4) {
    lcd.clear();
    lcd.print("Press to Recover");
    lcd.setCursor(0, 1);
    lcd.print(fakeMem[selectedMem].substring(0,15));
    if (joyPress == LOW) { 
      while(digitalRead(JOY_SW) == LOW) delay(10);
      memState = 5;
      unsigned long recoverStart = millis();
      
      // 6秒倒计时
      while (millis() - recoverStart < 6000) {
        lcd.clear();
        lcd.print("Recovering:");
        int remaining = 6 - (millis() - recoverStart)/1000;
        lcd.setCursor(0, 1);
        lcd.print(String(remaining) + "s Left");
        
        recoverProgress = millis() - recoverStart;
        int redBright = map(recoverProgress, 0, 6000, 0, 255);
        analogWrite(LED_RED, redBright); 
        analogWrite(LED_YELLOW, 0); 
        
        if ((millis() - recoverStart)%1000 == 0) tone(BUZZER, 3000, 100);
        delay(50);
      }
      memState = 6; 
    }
  }

  // 状态6：恢复失败
  else if (memState == 6) {
    lcd.clear();
    lcd.print("Recovery Failed");
    lcd.setCursor(0, 1);
    lcd.print(fakeMem[selectedMem].substring(0,15));
    for (int i=0; i<5; i++) {
      analogWrite(LED_RED, 255); 
      tone(BUZZER, 1000, 400);   
      delay(500);
      analogWrite(LED_RED, 0);
      noTone(BUZZER);
      delay(500);
    }
    tone(BUZZER, 600, 500);
    delay(500);
    tone(BUZZER, 400, 800);
    noTone(BUZZER);
    
    // 重置初始状态
    delay(2000);
    memState = 0;
    analogWrite(LED_RED, 0);
    analogWrite(LED_YELLOW, 255);
    analogWrite(LED_BLUE, 0);
    lcd.clear();
    lcd.print("Press Button to");
    lcd.setCursor(0, 1);
    lcd.print(" Start Select !");
  }

  // 稳定发送串口数据（每秒10次）
  if (millis() - lastSendTime > 100) {
    lastSendTime = millis();
    Serial.print(memState);Serial.print(",");
    Serial.print(selectedMem);Serial.print(",");
    Serial.print(charIndex);Serial.print(",");
    Serial.print(currentReplaceStart);Serial.print(",");
    Serial.print(syncState);Serial.print(",");
    Serial.println(recoverProgress);
  }

  delay(10);
}

// 摇杆选记忆函数
void selectMemoryByJoy(int joyXValue) {
  if (joyXValue < 300 && selectedMem > 0) {
    selectedMem--;
    currentReplaceStart = replaceStart[selectedMem];
    lcd.clear();
    lcd.print("Select Memory:");
    lcd.setCursor(0, 1);
    lcd.print(realMem[selectedMem].substring(0,15));
    tone(BUZZER, 400, 100); 
    delay(300); 
  }
  if (joyXValue > 700 && selectedMem < 2) {
    selectedMem++;
    currentReplaceStart = replaceStart[selectedMem];
    lcd.clear();
    lcd.print("Select Memory:");
    lcd.setCursor(0, 1);
    lcd.print(realMem[selectedMem].substring(0,15));
    tone(BUZZER, 400, 100); 
    delay(300); 
  }
}


