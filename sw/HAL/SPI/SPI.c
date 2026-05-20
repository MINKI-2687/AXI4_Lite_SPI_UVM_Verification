/*
 * SPI.c
 *
 *  Created on: 2026. 5. 4.
 *      Author: kccistc
 */
#include "SPI.h"

void SPI_Init(uint8_t cpol, uint8_t cpha, uint8_t clk_div)
{
    // 각 설정값을 비트 시프트(<<) 연산으로 제자리에 밀어넣고 OR(|)로 합칩니다
    SPI_PORT->CTRL = (clk_div << 8) | (cpha << 1) | cpol;
}

uint8_t SPI_Transfer(uint8_t tx_data)
{
    // 1. [핵심 수정] 송신 데이터 장전 및 Start 펄스 발생
    // 1U를 사용하여 안전하게 최상위 비트를 세팅하고, 즉시 0으로 내려 하드웨어 오작동을 막습니다.
    SPI_PORT->TX_DATA = (1U << 31) | tx_data;
    SPI_PORT->TX_DATA = tx_data; // Start 비트 즉시 해제 (데이터만 유지)

    // 2. 통신이 끝날 때까지 대기 (busy 비트가 9번 비트)[cite: 20]
    // Start 펄스 인가 후 하드웨어가 통신을 마칠 때까지 안전하게 대기합니다.
    while ((SPI_PORT->STATUS_RX & (1 << 9)) != 0) {
        // 아무것도 하지 않고 대기[cite: 20]
    }

    // 3. 수신된 데이터(하위 8비트)만 뽑아서 반환
    return (uint8_t)(SPI_PORT->STATUS_RX & 0xFF);
}
