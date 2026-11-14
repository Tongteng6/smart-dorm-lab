/**
 * 展示层格式化工具：设备状态、数值与比较符的中文文案。
 */
import { Device, DeviceType, readProperty } from '../model/Device';

/** 设备一行式状态文案 */
export function deviceStatusText(device: Device): string {
  switch (device.type) {
    case DeviceType.LIGHT: {
      const on: boolean = readProperty(device, 'power') as boolean;
      const brightness: number = readProperty(device, 'brightness') as number;
      return on ? `已开启 · 亮度 ${brightness}%` : '已关闭';
    }
    case DeviceType.AC: {
      const on: boolean = readProperty(device, 'power') as boolean;
      const temp: number = readProperty(device, 'targetTemp') as number;
      return on ? `制冷中 · ${temp}°C` : '已关闭';
    }
    case DeviceType.CURTAIN: {
      const openness: number = readProperty(device, 'openness') as number;
      return openness <= 0 ? '已闭合' : `开合 ${openness}%`;
    }
    case DeviceType.FAN: {
      const on: boolean = readProperty(device, 'power') as boolean;
      const speed: number = readProperty(device, 'speed') as number;
      return on ? `运行中 · ${speed} 档` : '已关闭';
    }
    default:
      return '';
  }
}

/** 设备是否处于「活跃」状态，用于卡片高亮 */
export function deviceIsActive(device: Device): boolean {
  switch (device.type) {
    case DeviceType.CURTAIN: {
      const openness: number = readProperty(device, 'openness') as number;
      return openness > 0;
    }
    default:
      return readProperty(device, 'power') as boolean;
  }
}

/** 设备图标字符 */
export function deviceIcon(device: Device): string {
  switch (device.type) {
    case DeviceType.LIGHT:
      return '💡';
    case DeviceType.AC:
      return '❄';
    case DeviceType.CURTAIN:
      return '🪟';
    case DeviceType.FAN:
      return '🌀';
    default:
      return '⚙';
  }
}

/** 数值型属性值的单位 */
export function valueUnit(prop: string): string {
  switch (prop) {
    case 'brightness':
      return '%';
    case 'targetTemp':
      return '°C';
    case 'openness':
      return '%';
    case 'speed':
      return ' 档';
    default:
      return '';
  }
}
