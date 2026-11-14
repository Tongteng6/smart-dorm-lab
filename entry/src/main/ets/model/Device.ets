/**
 * 设备模型：4 类可控设备与它们的可写属性。
 * 设备状态用可选字段承载，读写一律走辅助函数，避免字符串下标访问。
 */
import {
  AC_TEMP_MAX,
  AC_TEMP_MIN,
  BRIGHTNESS_MAX,
  BRIGHTNESS_MIN,
  CURTAIN_MAX,
  CURTAIN_MIN,
  FAN_SPEED_MAX,
  FAN_SPEED_MIN
} from '../common/Constants';

export enum DeviceType {
  LIGHT = 'LIGHT',
  AC = 'AC',
  CURTAIN = 'CURTAIN',
  FAN = 'FAN'
}

/** 可写属性名 */
export type DeviceProperty = 'power' | 'brightness' | 'targetTemp' | 'openness' | 'speed';

/** 设备当前状态。不同设备只用其中一部分字段 */
export interface DeviceState {
  power?: boolean;
  brightness?: number;
  targetTemp?: number;
  openness?: number;
  speed?: number;
}

export interface Device {
  id: string;
  type: DeviceType;
  name: string;
  /** 是否为开关类属性为主 */
  state: DeviceState;
}

/** 判定某属性是否属于数值型 */
export function isNumberProperty(prop: DeviceProperty): boolean {
  return prop !== 'power';
}

/** 读取属性值；未设置的数值返回 0，未设置的开关返回 false */
export function readProperty(device: Device, prop: DeviceProperty): number | boolean {
  switch (prop) {
    case 'power':
      return device.state.power === undefined ? false : device.state.power;
    case 'brightness':
      return device.state.brightness === undefined ? 0 : device.state.brightness;
    case 'targetTemp':
      return device.state.targetTemp === undefined ? AC_TEMP_MIN : device.state.targetTemp;
    case 'openness':
      return device.state.openness === undefined ? 0 : device.state.openness;
    case 'speed':
      return device.state.speed === undefined ? FAN_SPEED_MIN : device.state.speed;
    default:
      return 0;
  }
}

/** 写入属性值（就地修改），返回是否真的发生了变化 */
export function writeProperty(device: Device, prop: DeviceProperty, value: number | boolean): boolean {
  const before: number | boolean = readProperty(device, prop);
  if (before === value) {
    return false;
  }
  if (prop === 'power') {
    if (typeof value === 'boolean') {
      device.state.power = value;
    }
    return true;
  }
  if (typeof value !== 'number') {
    return false;
  }
  switch (prop) {
    case 'brightness':
      device.state.brightness = value;
      break;
    case 'targetTemp':
      device.state.targetTemp = value;
      break;
    case 'openness':
      device.state.openness = value;
      break;
    case 'speed':
      device.state.speed = value;
      break;
    default:
      break;
  }
  return true;
}

/** 属性取值范围（数值型） */
export function propertyRange(prop: DeviceProperty): number[] {
  switch (prop) {
    case 'brightness':
      return [BRIGHTNESS_MIN, BRIGHTNESS_MAX];
    case 'targetTemp':
      return [AC_TEMP_MIN, AC_TEMP_MAX];
    case 'openness':
      return [CURTAIN_MIN, CURTAIN_MAX];
    case 'speed':
      return [FAN_SPEED_MIN, FAN_SPEED_MAX];
    default:
      return [0, 1];
  }
}

/** 校验某个值是否可以写入该属性（需求 6：越界动作拒绝执行） */
export function isValidPropertyValue(prop: DeviceProperty, value: number | boolean): boolean {
  if (prop === 'power') {
    return typeof value === 'boolean';
  }
  if (typeof value !== 'number' || Number.isNaN(value)) {
    return false;
  }
  const range: number[] = propertyRange(prop);
  return value >= range[0] && value <= range[1];
}

/** 该设备是否拥有某属性 */
export function deviceHasProperty(type: DeviceType, prop: DeviceProperty): boolean {
  switch (type) {
    case DeviceType.LIGHT:
      return prop === 'power' || prop === 'brightness';
    case DeviceType.AC:
      return prop === 'power' || prop === 'targetTemp';
    case DeviceType.CURTAIN:
      return prop === 'openness';
    case DeviceType.FAN:
      return prop === 'power' || prop === 'speed';
    default:
      return false;
  }
}

export function propertyLabel(prop: DeviceProperty): string {
  switch (prop) {
    case 'power':
      return '开关';
    case 'brightness':
      return '亮度';
    case 'targetTemp':
      return '设定温度';
    case 'openness':
      return '开合度';
    case 'speed':
      return '档位';
    default:
      return prop;
  }
}

/** 出厂 4 台设备 */
export function defaultDevices(): Device[] {
  return [
    {
      id: 'light',
      type: DeviceType.LIGHT,
      name: '顶灯',
      state: { power: false, brightness: 60 }
    },
    {
      id: 'ac',
      type: DeviceType.AC,
      name: '空调',
      state: { power: false, targetTemp: 26 }
    },
    {
      id: 'curtain',
      type: DeviceType.CURTAIN,
      name: '窗帘',
      state: { openness: 0 }
    },
    {
      id: 'fan',
      type: DeviceType.FAN,
      name: '风扇',
      state: { power: false, speed: 1 }
    }
  ];
}

/** 深拷贝，保证引擎计算不污染入参（纯函数要求） */
export function cloneDevice(device: Device): Device {
  const state: DeviceState = {};
  if (device.state.power !== undefined) {
    state.power = device.state.power;
  }
  if (device.state.brightness !== undefined) {
    state.brightness = device.state.brightness;
  }
  if (device.state.targetTemp !== undefined) {
    state.targetTemp = device.state.targetTemp;
  }
  if (device.state.openness !== undefined) {
    state.openness = device.state.openness;
  }
  if (device.state.speed !== undefined) {
    state.speed = device.state.speed;
  }
  return { id: device.id, type: device.type, name: device.name, state: state };
}

export function cloneDevices(devices: Device[]): Device[] {
  return devices.map((d: Device) => cloneDevice(d));
}
