/**
 * 全局常量与取值边界。
 * 所有校验逻辑一律引用本文件，避免魔法数字散落各处。
 */
/** 环境指标取值范围 */
export const TEMP_MIN: number = -10;
export const TEMP_MAX: number = 50;
export const LUX_MIN: number = 0;
export const LUX_MAX: number = 2000;
export const HUMIDITY_MIN: number = 0;
export const HUMIDITY_MAX: number = 100;
/** 设备属性取值范围 */
export const BRIGHTNESS_MIN: number = 0;
export const BRIGHTNESS_MAX: number = 100;
export const AC_TEMP_MIN: number = 16;
export const AC_TEMP_MAX: number = 30;
export const CURTAIN_MIN: number = 0;
export const CURTAIN_MAX: number = 100;
export const FAN_SPEED_MIN: number = 1;
export const FAN_SPEED_MAX: number = 3;
/** 规则优先级 */
export const PRIORITY_MIN: number = 1;
export const PRIORITY_MAX: number = 10;
export const PRIORITY_DEFAULT: number = 5;
/** 日志容量 */
export const MAX_LOG_COUNT: number = 100;
/** 存储 key */
export const KEY_RULES: string = 'app.rules';
export const KEY_DEVICES: string = 'app.devices';
export const KEY_ENV: string = 'app.env';
export const KEY_LOGS: string = 'app.logs';
export const KEY_SCENARIOS: string = 'app.scenarios';
export const KEY_VERSION: string = 'app.version';
export const SCHEMA_VERSION: number = 1;
