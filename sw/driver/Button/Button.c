#include "Button.h"

void Button_Init(hBtn_t *hbtn, GPIO_Typedef_t *GPIOx, uint32_t GPIO_Pin)
{
    GPIO_SetMode(GPIOx, GPIO_Pin, INPUT);

    hbtn->GPIOx = GPIOx;
    hbtn->GPIO_Pin = GPIO_Pin;
    hbtn->prevState = RELEASED;
}

button_act_t Button_GetState(hBtn_t *hbtn)
{
    button_state_t curState = GPIO_ReadPin(hbtn->GPIOx, hbtn->GPIO_Pin);
    if (hbtn->prevState == RELEASED && curState == PUSHED) {
        delay_ms(5);
        hbtn->prevState = PUSHED;
        return ACT_PUSHED;
    }
    else if (hbtn->prevState == PUSHED && curState == RELEASED) {
        delay_ms(5);
        hbtn->prevState = RELEASED;
        return ACT_RELEASED;
    }
    return NO_ACT;
}
