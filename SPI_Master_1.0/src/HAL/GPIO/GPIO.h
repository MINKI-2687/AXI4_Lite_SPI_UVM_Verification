#ifndef SRC_HAL_GPIO_GPIO_H_
#define SRC_HAL_GPIO_GPIO_H_

#include <stdint.h>

typedef struct {
	volatile uint32_t CR;
	volatile uint32_t IDR;
	volatile uint32_t ODR;
} GPIO_Typedef_t;

#define GPIOA_BASE_ADDR 0x44A10000
#define GPIOB_BASE_ADDR 0x44A20000
#define GPIOC_BASE_ADDR 0x44A30000

#define GPIOA_CR	(*(uint32_t *) (GPIOA_BASE_ADDR + 0x00))
#define GPIOA_IDR	(*(uint32_t *) (GPIOA_BASE_ADDR + 0x04))
#define GPIOA_ODR	(*(uint32_t *) (GPIOA_BASE_ADDR + 0x08))

#define GPIOB_CR	(*(uint32_t *) (GPIOB_BASE_ADDR + 0x00))
#define GPIOB_IDR	(*(uint32_t *) (GPIOB_BASE_ADDR + 0x04))
#define GPIOB_ODR	(*(uint32_t *) (GPIOB_BASE_ADDR + 0x08))

#define GPIOC_CR	(*(uint32_t *) (GPIOC_BASE_ADDR + 0x00))
#define GPIOC_IDR	(*(uint32_t *) (GPIOC_BASE_ADDR + 0x04))
#define GPIOC_ODR	(*(uint32_t *) (GPIOC_BASE_ADDR + 0x08))

#define GPIOA	((GPIO_Typedef_t *) (GPIOA_BASE_ADDR))
#define GPIOB	((GPIO_Typedef_t *) (GPIOB_BASE_ADDR))
#define GPIOC	((GPIO_Typedef_t *) (GPIOC_BASE_ADDR))

#define GPIO_PIN_0 0x01	// 0b00000001
#define GPIO_PIN_1 0x02	// 0b00000010
#define GPIO_PIN_2 0x04	// 0b00000100
#define GPIO_PIN_3 0x08	// 0b00001000
#define GPIO_PIN_4 0x10	// 0b00010000
#define GPIO_PIN_5 0x20	// 0b00100000
#define GPIO_PIN_6 0x40	// 0b01000000
#define GPIO_PIN_7 0x80	// 0b10000000

#define INPUT	0	
#define OUTPUT	1	

#define RESET	0
#define SET 	1

void GPIO_SetMode(GPIO_Typedef_t *GPIOx, uint32_t GPIO_Pin, int GPIO_Dir);
void GPIO_WritePin(GPIO_Typedef_t *GPIOx, uint32_t GPIO_Pin, int level);
uint32_t GPIO_ReadPin(GPIO_Typedef_t *GPIOx, uint32_t GPIO_Pin);
void GPIO_WritePort(GPIO_Typedef_t *GPIOx, int data);
uint32_t GPIO_ReadPort(GPIO_Typedef_t *GPIOx);

#endif /* SRC_HAL_GPIO_GPIO_H_ */
