/*
 * Switch.c
 *
 *  Created on: 2026. 5. 4.
 *      Author: kccistc
 */

#include "Switch.h"

void Switch_Init(void)
{
    // GPIOC의 하위 8개 핀(SWITCH_PINS)을 한 번에 입력(INPUT) 모드로 설정합니다.
    GPIO_SetMode(SWITCH_PORT, SWITCH_PINS, INPUT);
}

uint8_t Switch_GetState(void)
{
    // GPIOC 포트 전체(32비트)를 한 번에 확 읽어온 다음,
    // AND 연산(& 0xFF)을 통해 우리가 사용하는 하위 8비트 스위치 값만 깔끔하게 걸러서 반환합니다.
    return (uint8_t)(GPIO_ReadPort(SWITCH_PORT) & SWITCH_PINS);
}
