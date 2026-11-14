import { HUMIDITY_MAX, HUMIDITY_MIN, LUX_MAX, LUX_MIN, TEMP_MAX, TEMP_MIN } from "@normalized:N&&&entry/src/main/ets/common/Constants&";
/** 可被规则引用的环境指标 */
export type MetricKey = 'temperature' | 'illuminance' | 'humidity' | 'presence';
export interface EnvState {
    temperature: number;
    illuminance: number;
    humidity: number;
    presence: boolean;
}
/** 出厂默认环境：白天、有人、温度适中 */
export function defaultEnv(): EnvState {
    return {
        temperature: 26,
        illuminance: 500,
        humidity: 55,
        presence: true
    };
}
/** 按指标名读取环境值，统一入口，避免调用方使用字符串下标 */
export function readMetric(env: EnvState, key: MetricKey): number | boolean {
    switch (key) {
        case 'temperature':
            return env.temperature;
        case 'illuminance':
            return env.illuminance;
        case 'humidity':
            return env.humidity;
        case 'presence':
            return env.presence;
        default:
            return 0;
    }
}
/** 指标的中文展示名 */
export function metricLabel(key: MetricKey): string {
    switch (key) {
        case 'temperature':
            return '温度';
        case 'illuminance':
            return '光照';
        case 'humidity':
            return '湿度';
        case 'presence':
            return '有人';
        default:
            return key;
    }
}
/** 指标单位 */
export function metricUnit(key: MetricKey): string {
    switch (key) {
        case 'temperature':
            return '°C';
        case 'illuminance':
            return 'lux';
        case 'humidity':
            return '%';
        default:
            return '';
    }
}
/** 把单个数值钳制到合法区间 */
export function clampNumber(value: number, min: number, max: number): number {
    if (Number.isNaN(value)) {
        return min;
    }
    if (value < min) {
        return min;
    }
    if (value > max) {
        return max;
    }
    return value;
}
/**
 * 钳制整份环境数据。
 * 越界输入不报错、不写入非法值，而是修正到合法边界（需求 6）。
 */
export function clampEnv(env: EnvState): EnvState {
    return {
        temperature: clampNumber(env.temperature, TEMP_MIN, TEMP_MAX),
        illuminance: clampNumber(env.illuminance, LUX_MIN, LUX_MAX),
        humidity: clampNumber(env.humidity, HUMIDITY_MIN, HUMIDITY_MAX),
        presence: env.presence
    };
}
