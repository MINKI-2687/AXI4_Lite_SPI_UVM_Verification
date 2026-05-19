/*
 * SPI.h
 *
 *  Created on: 2026. 5. 4.
 *      Author: kccistc
 */

#ifndef SRC_HAL_SPI_SPI_H_
#define SRC_HAL_SPI_SPI_H_

#include <stdint.h>

// Verilog에서 설계한 3개의 32비트 레지스터를 구조체로 묶음
typedef struct {
    volatile uint32_t CTRL;      // 0x00: slv_reg0 (cpol, cpha, clk_div)
    volatile uint32_t TX_DATA;   // 0x04: slv_reg1 (start, tx_data)
    volatile uint32_t STATUS_RX; // 0x08: slv_reg2 (busy, done, rx_data)
} SPI_Typedef_t;

// xparameters.h에 나와있는 SPI_MASTER의 베이스 주소
#define SPI_BASE_ADDR 0x44A00000
#define SPI_PORT ((SPI_Typedef_t *) SPI_BASE_ADDR)

// 함수 프로토타입
void SPI_Init(uint8_t cpol, uint8_t cpha, uint8_t clk_div);
uint8_t SPI_Transfer(uint8_t tx_data); // 송신과 수신을 동시에 처리하는 함수

#endif /* SRC_HAL_SPI_SPI_H_ */
