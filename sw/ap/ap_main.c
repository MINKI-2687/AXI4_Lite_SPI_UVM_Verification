#include "ap_main.h"
#include "spi_ap/spi_ap.h"

void ap_init(void) {
    // 시스템 켜질 때 단 한 번, 통신 모듈 초기화 지시
    Spi_Ap_Init();
}

void ap_execute(void) {
    while (1) {
        // 무한 루프 내내 통신 시나리오 감시 및 실행
        Spi_Ap_Run();
    }
}
