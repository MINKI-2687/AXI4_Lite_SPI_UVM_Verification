/*
 * spi_ap.c
 *
 *  Created on: 2026. 5. 4.
 *      Author: kccistc
 */

#include "spi_ap.h"
#include "../../common/common.h"
#include "../../driver/Switch/Switch.h"
#include "../../driver/Button/Button.h"
#include "../../driver/FND/FND.h"
#include "../../HAL/SPI/SPI.h"

// XDC에 선언된 통신 시작 버튼 (GPIOA의 4번 비트 T18 핀 사용 가정)
hBtn_t hbtnStart;

void Spi_Ap_Init() {
	// 1. 통신 시작용 버튼 초기화 (GPIOA, 4번 핀)
	Button_Init(&hbtnStart, GPIOA, GPIO_PIN_4);

	// 2. 스위치 및 FND 초기화
	Switch_Init();
	FND_Init();

	// 3. SPI 초기화 (cpol=0, cpha=0, clk_div=4로 세팅했다고 가정)
	// 분주비(clk_div)는 본인의 하드웨어 설계에 맞게 숫자를 넣어주세요.
	SPI_Init(0, 0, 50);

	// 초기 FND 화면을 0으로 셋팅
	FND_SetNum(0);
}

void Spi_Ap_Run() {
	uint8_t sw_data = 0;
	uint8_t rx_data = 0;

	// ==========================================
	// [이벤트 감지 영역] : 버튼이 눌렸을 때 단 한 번 실행
	// ==========================================
	if (Button_GetState(&hbtnStart) == ACT_PUSHED) {
		// 1. 장전된 스위치 데이터 읽기
		sw_data = Switch_GetState();

		// 2. SPI 하드웨어로 데이터 쏘고, 동시에 받아오기
		rx_data = SPI_Transfer(sw_data);

		// 3. 받아온 데이터를 FND 전역 변수에 덮어쓰기
		FND_SetNum(rx_data);
	}

	// ==========================================
	// [무한 반복 영역] : 루프를 돌 때마다 항상 실행
	// ==========================================
	// FND는 4개의 자리가 한 번에 켜질 수 없으므로,
	// 루프를 돌 때마다 한 자리씩 번갈아가며 켭니다. (잔상 효과)
	FND_DispDigit();
	delay_ms(1); // 2ms 딜레이 (너무 빠르면 숫자가 겹쳐보이고, 느리면 깜빡거림)
}
