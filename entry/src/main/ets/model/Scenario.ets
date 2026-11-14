/**
 * 场景模型：一组预设的环境指标，用于一键演练。
 */
import { EnvState } from './EnvState';

export interface Scenario {
  id: string;
  name: string;
  /** 简单图标字符，避免额外资源依赖 */
  icon: string;
  env: EnvState;
}

export function newScenarioId(): string {
  const rand: number = Math.floor(Math.random() * 100000);
  return `sc-${Date.now()}-${rand}`;
}

export function defaultScenarios(): Scenario[] {
  return [
    {
      id: 'sc-day',
      name: '白天有人',
      icon: '☀',
      env: { temperature: 29, illuminance: 900, humidity: 45, presence: true }
    },
    {
      id: 'sc-night',
      name: '夜间归寝',
      icon: '🌙',
      env: { temperature: 24, illuminance: 60, humidity: 55, presence: true }
    },
    {
      id: 'sc-rain',
      name: '梅雨潮湿',
      icon: '🌧',
      env: { temperature: 27, illuminance: 320, humidity: 86, presence: true }
    },
    {
      id: 'sc-empty',
      name: '无人在寝',
      icon: '🚪',
      env: { temperature: 30, illuminance: 700, humidity: 50, presence: false }
    }
  ];
}
