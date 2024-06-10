#include <lvgl.h>
#include "ui.h"
#include "rm67162.h"

/*Change to your screen resolution*/
static const uint16_t screenWidth = 536;
static const uint16_t screenHeight = 240;

static lv_disp_draw_buf_t draw_buf;
static lv_color_t buf[screenWidth * screenHeight / 10];

void my_disp_flush(lv_disp_drv_t *disp,
                   const lv_area_t *area,
                   lv_color_t *color_p) {
  uint32_t w = (area->x2 - area->x1 + 1);
  uint32_t h = (area->y2 - area->y1 + 1);
  lcd_PushColors(area->x1, area->y1, w, h, (uint16_t *)&color_p->full);
  lv_disp_flush_ready(disp);
}

#define MAX_SCREEN_INDEX 2
bool lcdIsOff = true;
lv_chart_series_t *cpuTempChart;
lv_chart_series_t *cpuLoadChart;
lv_chart_series_t *cpuRamChart;
lv_chart_series_t *gpuTempChart;
lv_chart_series_t *gpuLoadChart;
lv_chart_series_t *gpuRamChart;

lv_obj_t *screens[MAX_SCREEN_INDEX + 1];

void setup() {
  rm67162_init();  // amoled lcd initialization
  lcd_setRotation(1);
  lcd_display_off();

  Serial.begin(921600);
  Serial.setTimeout(100);
  while (!Serial) {
    ;
  }

  lv_init();

  lv_disp_draw_buf_init(&draw_buf, buf, NULL, screenWidth * screenHeight / 10);

  /*Initialize the display*/
  static lv_disp_drv_t disp_drv;
  lv_disp_drv_init(&disp_drv);
  /*Change the following line to your display resolution*/
  disp_drv.hor_res = screenWidth;
  disp_drv.ver_res = screenHeight;
  disp_drv.flush_cb = my_disp_flush;
  disp_drv.draw_buf = &draw_buf;
  lv_disp_drv_register(&disp_drv);


  ui_init();

  cpuTempChart = lv_chart_add_series(ui_cpuTempChart, lv_color_hex(0xED1C24), LV_CHART_AXIS_PRIMARY_Y);
  cpuLoadChart = lv_chart_add_series(ui_cpuTempChart, lv_color_hex(0x2095F6), LV_CHART_AXIS_SECONDARY_Y);
  cpuRamChart = lv_chart_add_series(ui_cpuTempChart, lv_color_hex(0x808080), LV_CHART_AXIS_SECONDARY_Y);
  gpuTempChart = lv_chart_add_series(ui_gpuTempChart, lv_color_hex(0x76b900), LV_CHART_AXIS_PRIMARY_Y);
  gpuLoadChart = lv_chart_add_series(ui_gpuTempChart, lv_color_hex(0x2095F6), LV_CHART_AXIS_SECONDARY_Y);
  gpuRamChart = lv_chart_add_series(ui_gpuTempChart, lv_color_hex(0x808080), LV_CHART_AXIS_SECONDARY_Y);

  screens[0] = ui_summaryScreen;
  screens[1] = ui_cpuTempChartScreen;
  screens[2] = ui_gpuTempChartScreen;
}

#define packetSizesLen 10
byte packetSizes[] PROGMEM = {
  0x00,  //0x00 = Identify()
  0x01,  //0x01 = SwitchPage(pageNum)
  0x05,  //0x02 = setDateTime(hh,mm,dd,MM,yy)
  0x10,  //0x03 = setSensorData(cpuClock, cpuTemp, cpuLoad, cpuRam, gpuClock, gpuTemp, gpuLoad, gpuRam)
  0x00,  //0x04 = lcd_sleep()
  0x00,  //0x05 = screen_next()
  0x00,  //0x06 = screen_previous()
  0x66,  //0x07 = notify(duration, blink, title[50], body[50])
  0x10,  //0x08 = setSensorData(cpuClock, cpuTemp, cpuLoad, cpuRam, null, gpuTemp, gpuLoad, gpuRam) -- mac version
  0x97,  //0x09 = nowPlaying(duration, title[50], artist+album[100])
};

int screenIndex = 0;
int incomingByte = 0;
size_t retData;
char buffer[256];
char clockFmt[6] = { 0 };
char dateFmt[11] = { 0 };
uint cputemp;
uint gputemp;
uint cpuload;
uint gpuload;
uint cpuram;
uint gpuram;
int autoTurnoffDelay = 6000;
int notificationTimer = 0;
bool notificationBlink = false;
int notificationBlinkTimer = 100;
bool notificationOrangeIcon = false;
int musicTimer = 0;

void loop() {
  lv_timer_handler(); /* let the GUI do its work */

  if (Serial.available() > 0) {
    int incomingByte = Serial.read();
    if (incomingByte >= 0 && incomingByte < packetSizesLen) {
      retData = Serial.readBytes(buffer, packetSizes[incomingByte]);
      if (retData == packetSizes[incomingByte]) {
        buffer[retData] = 0x00;
        autoTurnoffDelay = 6000;
        switch (incomingByte) {
          case 0x00:
            Serial.println('AMOLED Status Display');
            break;
          case 0x01:
            switch (buffer[0]) {
              case 0:
                lv_disp_load_scr(ui_summaryScreen);
                break;
              case 1:
                lv_disp_load_scr(ui_cpuTempChartScreen);
                break;
            }
            break;
          case 0x02:
            sprintf(clockFmt, "%02d:%02d", buffer[0], buffer[1]);
            sprintf(dateFmt, "%02d/%02d/%04d", buffer[2], buffer[3], 2000 + ((int)buffer[4]));
            lv_label_set_text_static(ui_comp_get_child(ui_topBar, UI_COMP_TOPBAR_TOPBARCLOCK), clockFmt);
            lv_label_set_text_static(ui_comp_get_child(ui_topBar, UI_COMP_TOPBAR_TOPBARDATE), dateFmt);
            lv_label_set_text_static(ui_comp_get_child(ui_topBar1, UI_COMP_TOPBAR_TOPBARCLOCK), clockFmt);
            lv_label_set_text_static(ui_comp_get_child(ui_topBar1, UI_COMP_TOPBAR_TOPBARDATE), dateFmt);
            lv_label_set_text_static(ui_comp_get_child(ui_topBar2, UI_COMP_TOPBAR_TOPBARCLOCK), clockFmt);
            lv_label_set_text_static(ui_comp_get_child(ui_topBar2, UI_COMP_TOPBAR_TOPBARDATE), dateFmt);
            lv_label_set_text_static(ui_comp_get_child(ui_topBar3, UI_COMP_TOPBAR_TOPBARCLOCK), clockFmt);
            lv_label_set_text_static(ui_comp_get_child(ui_topBar3, UI_COMP_TOPBAR_TOPBARDATE), dateFmt);
            lv_label_set_text_static(ui_comp_get_child(ui_topBar4, UI_COMP_TOPBAR_TOPBARCLOCK), clockFmt);
            lv_label_set_text_static(ui_comp_get_child(ui_topBar4, UI_COMP_TOPBAR_TOPBARDATE), dateFmt);
            break;
          case 0x08:
          case 0x03:
            cputemp = (buffer[3] << 8) + buffer[2];
            gputemp = (buffer[11] << 8) + buffer[10];
            cpuload = (buffer[5] << 8) + buffer[4];
            gpuload = (buffer[13] << 8) + buffer[12];
            cpuram = (buffer[7] << 8) + buffer[6];
            gpuram = (buffer[15] << 8) + buffer[14];
            if (incomingByte == 0x03) {
              lv_label_set_text_fmt(ui_cpuMhz, "%d MHz", (buffer[1] << 8) + buffer[0]);
              lv_label_set_text_fmt(ui_gpuMhz, "%d MHz", (buffer[9] << 8) + buffer[8]);
              lv_label_set_text(ui_summaryMiddle, "");
            } else {
              lv_label_set_text(ui_cpuMhz, "");
              lv_label_set_text(ui_gpuMhz, "");
              lv_label_set_text_fmt(ui_summaryMiddle, "%d W", (buffer[1] << 8) + buffer[0]);
            }
            lv_label_set_text_fmt(ui_cpuTemp, "%d C", cputemp);
            lv_label_set_text_fmt(ui_cpuRam, "%d %%", cpuram);
            lv_label_set_text_fmt(ui_gpuTemp, "%d C", gputemp);
            lv_label_set_text_fmt(ui_gpuRam, "%d %%", gpuram);
            lv_arc_set_value(ui_cpuArc, cpuload);
            lv_arc_set_value(ui_gpuArc, gpuload);
            lv_chart_set_next_value(ui_cpuTempChart, cpuTempChart, cputemp);
            lv_chart_set_next_value(ui_gpuTempChart, gpuTempChart, gputemp);
            lv_chart_set_next_value(ui_cpuTempChart, cpuLoadChart, cpuload);
            lv_chart_set_next_value(ui_gpuTempChart, gpuLoadChart, gpuload);
            lv_chart_set_next_value(ui_cpuTempChart, cpuRamChart, cpuram);
            lv_chart_set_next_value(ui_gpuTempChart, gpuRamChart, gpuram);
            break;
          case 0x04:
            lcd_display_off();
            lcdIsOff = true;
            break;
          case 0x05:
            if (screenIndex >= MAX_SCREEN_INDEX)
              screenIndex = 0;
            else
              screenIndex++;
            lv_disp_load_scr(screens[screenIndex]);
            break;
          case 0x06:
            if (screenIndex <= 0)
              screenIndex = MAX_SCREEN_INDEX;
            else
              screenIndex--;
            lv_disp_load_scr(screens[screenIndex]);
            break;
          case 0x07:
            notificationTimer = ((int)buffer[0]) * 200;
            notificationBlink = buffer[1] > 0;
            lv_label_set_text(ui_notificationTitle, &buffer[2]);
            lv_label_set_text(ui_notificationBody, &buffer[52]);
            lv_disp_load_scr(ui_notificationScreen);
            break;
          case 0x09:
            notificationTimer = ((int)buffer[0]) * 200;
            lv_label_set_text(ui_musicTitle, &buffer[1]);
            lv_label_set_text(ui_musicArtist, &buffer[51]);
            lv_disp_load_scr(ui_musicScreen);
            break;
        }
        if (incomingByte != 0x04) {
          lv_refr_now(NULL);
          if (lcdIsOff) {
            lcd_display_on();
            lcdIsOff = false;
          }
        }
        Serial.write(0x00);
      } else {
        Serial.write(retData);
      }
      Serial.flush();
    }
  }

  if (musicTimer > 0) {
    musicTimer--;
    if (musicTimer == 0) {
      lv_disp_load_scr(screens[screenIndex]);
      lv_refr_now(NULL);
    }
  }

  if (notificationTimer > 0) {
    notificationTimer--;
    if (notificationTimer == 0) {
      notificationOrangeIcon = false;
      lv_img_set_src(ui_bell, &ui_img_bluebell_png);
      lv_disp_load_scr(screens[screenIndex]);
      lv_refr_now(NULL);
    } else if (notificationBlink) {
      if (notificationBlinkTimer > 0) {
        notificationBlinkTimer--;
      } else {
        notificationBlinkTimer = 100;
        notificationOrangeIcon = !notificationOrangeIcon;
        lv_img_set_src(ui_bell, notificationOrangeIcon ? &ui_img_orangebell_png : &ui_img_bluebell_png);
        lv_refr_now(NULL);
      }
    }
  }

  if (autoTurnoffDelay > 0) {
    autoTurnoffDelay--;
  } else if (!lcdIsOff) {
    lcd_display_off();
    lcdIsOff = true;
  }
  delay(5);
}
