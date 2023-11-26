// This file was generated by SquareLine Studio
// SquareLine Studio version: SquareLine Studio 1.3.3
// LVGL version: 8.3.6
// Project name: SquareLine_Project

#include "ui.h"

void ui_summaryScreen_screen_init(void)
{
ui_summaryScreen = lv_obj_create(NULL);
lv_obj_clear_flag( ui_summaryScreen, LV_OBJ_FLAG_SCROLLABLE );    /// Flags
lv_obj_set_style_bg_color(ui_summaryScreen, lv_color_hex(0x000000), LV_PART_MAIN | LV_STATE_DEFAULT );
lv_obj_set_style_bg_opa(ui_summaryScreen, 255, LV_PART_MAIN| LV_STATE_DEFAULT);

ui_cpuArc = lv_arc_create(ui_summaryScreen);
lv_obj_set_width( ui_cpuArc, 200);
lv_obj_set_height( ui_cpuArc, 200);
lv_obj_set_x( ui_cpuArc, -140 );
lv_obj_set_y( ui_cpuArc, 14 );
lv_obj_set_align( ui_cpuArc, LV_ALIGN_BOTTOM_MID );
lv_arc_set_value(ui_cpuArc, 50);
lv_arc_set_bg_angles(ui_cpuArc,150,30);


ui_cpuMhz = lv_label_create(ui_cpuArc);
lv_obj_set_width( ui_cpuMhz, LV_SIZE_CONTENT);  /// 1
lv_obj_set_height( ui_cpuMhz, LV_SIZE_CONTENT);   /// 1
lv_obj_set_x( ui_cpuMhz, 0 );
lv_obj_set_y( ui_cpuMhz, -10 );
lv_obj_set_align( ui_cpuMhz, LV_ALIGN_BOTTOM_MID );
lv_label_set_text(ui_cpuMhz,"5000 MHz");
lv_obj_set_style_text_font(ui_cpuMhz, &lv_font_montserrat_24, LV_PART_MAIN| LV_STATE_DEFAULT);

ui_cpuTitle = lv_label_create(ui_cpuArc);
lv_obj_set_width( ui_cpuTitle, LV_SIZE_CONTENT);  /// 1
lv_obj_set_height( ui_cpuTitle, LV_SIZE_CONTENT);   /// 1
lv_obj_set_x( ui_cpuTitle, 0 );
lv_obj_set_y( ui_cpuTitle, -60 );
lv_obj_set_align( ui_cpuTitle, LV_ALIGN_CENTER );
lv_label_set_text(ui_cpuTitle,"CPU");
lv_obj_set_style_text_color(ui_cpuTitle, lv_color_hex(0xED1C24), LV_PART_MAIN | LV_STATE_DEFAULT );
lv_obj_set_style_text_opa(ui_cpuTitle, 255, LV_PART_MAIN| LV_STATE_DEFAULT);
lv_obj_set_style_text_font(ui_cpuTitle, &lv_font_montserrat_24, LV_PART_MAIN| LV_STATE_DEFAULT);

ui_cpuTemp = lv_label_create(ui_cpuArc);
lv_obj_set_width( ui_cpuTemp, LV_SIZE_CONTENT);  /// 1
lv_obj_set_height( ui_cpuTemp, LV_SIZE_CONTENT);   /// 1
lv_obj_set_x( ui_cpuTemp, 0 );
lv_obj_set_y( ui_cpuTemp, -10 );
lv_obj_set_align( ui_cpuTemp, LV_ALIGN_CENTER );
lv_obj_set_style_text_font(ui_cpuTemp, &lv_font_montserrat_30, LV_PART_MAIN| LV_STATE_DEFAULT);

ui_cpuRam = lv_label_create(ui_cpuArc);
lv_obj_set_width( ui_cpuRam, LV_SIZE_CONTENT);  /// 1
lv_obj_set_height( ui_cpuRam, LV_SIZE_CONTENT);   /// 1
lv_obj_set_x( ui_cpuRam, 0 );
lv_obj_set_y( ui_cpuRam, 25 );
lv_obj_set_align( ui_cpuRam, LV_ALIGN_CENTER );
lv_obj_set_style_text_font(ui_cpuRam, &lv_font_montserrat_24, LV_PART_MAIN| LV_STATE_DEFAULT);

ui_gpuArc = lv_arc_create(ui_summaryScreen);
lv_obj_set_width( ui_gpuArc, 200);
lv_obj_set_height( ui_gpuArc, 200);
lv_obj_set_x( ui_gpuArc, 140 );
lv_obj_set_y( ui_gpuArc, 14 );
lv_obj_set_align( ui_gpuArc, LV_ALIGN_BOTTOM_MID );
lv_arc_set_value(ui_gpuArc, 50);
lv_arc_set_bg_angles(ui_gpuArc,150,30);


ui_gpuRam = lv_label_create(ui_gpuArc);
lv_obj_set_width( ui_gpuRam, LV_SIZE_CONTENT);  /// 1
lv_obj_set_height( ui_gpuRam, LV_SIZE_CONTENT);   /// 1
lv_obj_set_x( ui_gpuRam, 0 );
lv_obj_set_y( ui_gpuRam, 25 );
lv_obj_set_align( ui_gpuRam, LV_ALIGN_CENTER );
lv_obj_set_style_text_font(ui_gpuRam, &lv_font_montserrat_24, LV_PART_MAIN| LV_STATE_DEFAULT);

ui_gpuTitle = lv_label_create(ui_gpuArc);
lv_obj_set_width( ui_gpuTitle, LV_SIZE_CONTENT);  /// 1
lv_obj_set_height( ui_gpuTitle, LV_SIZE_CONTENT);   /// 1
lv_obj_set_x( ui_gpuTitle, 0 );
lv_obj_set_y( ui_gpuTitle, -60 );
lv_obj_set_align( ui_gpuTitle, LV_ALIGN_CENTER );
lv_label_set_text(ui_gpuTitle,"GPU");
lv_obj_set_style_text_color(ui_gpuTitle, lv_color_hex(0x76B900), LV_PART_MAIN | LV_STATE_DEFAULT );
lv_obj_set_style_text_opa(ui_gpuTitle, 255, LV_PART_MAIN| LV_STATE_DEFAULT);
lv_obj_set_style_text_font(ui_gpuTitle, &lv_font_montserrat_24, LV_PART_MAIN| LV_STATE_DEFAULT);

ui_gpuTemp = lv_label_create(ui_gpuArc);
lv_obj_set_width( ui_gpuTemp, LV_SIZE_CONTENT);  /// 1
lv_obj_set_height( ui_gpuTemp, LV_SIZE_CONTENT);   /// 1
lv_obj_set_x( ui_gpuTemp, 0 );
lv_obj_set_y( ui_gpuTemp, -10 );
lv_obj_set_align( ui_gpuTemp, LV_ALIGN_CENTER );
lv_obj_set_style_text_font(ui_gpuTemp, &lv_font_montserrat_30, LV_PART_MAIN| LV_STATE_DEFAULT);

ui_gpuMhz = lv_label_create(ui_gpuArc);
lv_obj_set_width( ui_gpuMhz, LV_SIZE_CONTENT);  /// 1
lv_obj_set_height( ui_gpuMhz, LV_SIZE_CONTENT);   /// 1
lv_obj_set_x( ui_gpuMhz, 0 );
lv_obj_set_y( ui_gpuMhz, -10 );
lv_obj_set_align( ui_gpuMhz, LV_ALIGN_BOTTOM_MID );
lv_obj_set_style_text_font(ui_gpuMhz, &lv_font_montserrat_24, LV_PART_MAIN| LV_STATE_DEFAULT);

ui_topBar = ui_topBar_create(ui_summaryScreen);
lv_obj_set_x( ui_topBar, 0 );
lv_obj_set_y( ui_topBar, 0 );




}
