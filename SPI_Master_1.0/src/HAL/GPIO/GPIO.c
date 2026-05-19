#include "GPIO.h"

void GPIO_SetMode(GPIO_Typedef_t *GPIOx, uint32_t GPIO_Pin, int GPIO_Dir)
{
	if (GPIO_Dir == OUTPUT) {
		GPIOx->CR |= GPIO_Pin;
	}
	else {
		GPIOx->CR &= ~(GPIO_Pin);
	}
}

void GPIO_WritePin(GPIO_Typedef_t *GPIOx, uint32_t GPIO_Pin, int level)
{
	if (level == SET) {
		GPIOx->ODR |= GPIO_Pin;
	}
	else {
		GPIOx->ODR &= ~(GPIO_Pin);
	}
}

uint32_t GPIO_ReadPin(GPIO_Typedef_t *GPIOx, uint32_t GPIO_Pin)
{
	return (GPIOx->IDR & GPIO_Pin) ? 1 : 0;
}

void GPIO_WritePort(GPIO_Typedef_t *GPIOx, int data)
{
	GPIOx->ODR = data;
}

uint32_t GPIO_ReadPort(GPIO_Typedef_t *GPIOx)
{
	return GPIOx->IDR;
}