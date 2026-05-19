/*
 * Switch.h
 *
 *  Created on: 2026. 5. 4.
 *      Author: kccistc
 */

#ifndef SRC_DRIVER_SWITCH_SWITCH_H_
#define SRC_DRIVER_SWITCH_SWITCH_H_

// 우리가 만든 Xilinx 호환 GPIO HAL을 불러옵니다.
#include "../../HAL/GPIO/GPIO.h"

// XDC 파일에 맞게 스위치가 연결된 포트를 GPIOC로 지정합니다.
#define SWITCH_PORT GPIOC

// 스위치 8개(0번~7번 비트)를 모두 1로 켠 마스크 값 (0b11111111 = 0xFF)
#define SWITCH_PINS 0xFF

void Switch_Init(void);
uint8_t Switch_GetState(void);

#endif /* SRC_DRIVER_SWITCH_SWITCH_H_ */
