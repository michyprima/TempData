SET(SOURCES ui_comp_topbar.c
    ui_comp.c
    ui_summaryScreen.c
    ui_cpuTempChartScreen.c
    ui_gpuTempChartScreen.c
    ui_notificationScreen.c
    ui_musicScreen.c
    ui.c
    ui_comp_hook.c
    ui_helpers.c
    ui_events.c
    ui_img_bluebell_png.c
    ui_img_music_png.c
    ui_img_orangebell_png.c)

add_library(ui ${SOURCES})
