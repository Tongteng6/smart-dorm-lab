/**
 * 仓储层：把内存中的业务快照与 Preferences 之间来回搬运。
 * 所有解析失败都回退到出厂数据，保证应用不会因为脏数据起不来（需求 6）。
 */
import {
  KEY_DEVICES,
  KEY_ENV,
  KEY_LOGS,
  KEY_RULES,
  KEY_SCENARIOS,
  KEY_VERSION,
  MAX_LOG_COUNT,
  SCHEMA_VERSION
} from '../common/Constants';
import { Device, defaultDevices } from '../model/Device';
import { EnvState, defaultEnv } from '../model/EnvState';
import { LogEntry } from '../model/LogEntry';
import { Rule } from '../model/Rule';
import { Scenario, defaultScenarios } from '../model/Scenario';
import { defaultRules } from '../model/Samples';
import { PreferencesStore } from './PreferencesStore';

export interface AppSnapshot {
  rules: Rule[];
  devices: Device[];
  env: EnvState;
  logs: LogEntry[];
  scenarios: Scenario[];
}

export class RuleRepository {
  private store: PreferencesStore = PreferencesStore.get();

  /** 读取全量数据；任何一段解析失败都单独回退，不影响其他部分 */
  async loadAll(): Promise<AppSnapshot> {
    const rulesText: string = await this.store.readString(KEY_RULES);
    const devicesText: string = await this.store.readString(KEY_DEVICES);
    const envText: string = await this.store.readString(KEY_ENV);
    const logsText: string = await this.store.readString(KEY_LOGS);
    const scenariosText: string = await this.store.readString(KEY_SCENARIOS);

    return {
      rules: this.parseRules(rulesText),
      devices: this.parseDevices(devicesText),
      env: this.parseEnv(envText),
      logs: this.parseLogs(logsText),
      scenarios: this.parseScenarios(scenariosText)
    };
  }

  private parseRules(text: string): Rule[] {
    if (text.length === 0) {
      return defaultRules();
    }
    try {
      const list: Rule[] = JSON.parse(text) as Rule[];
      if (!Array.isArray(list)) {
        return defaultRules();
      }
      return list;
    } catch (e) {
      console.error(`[RuleRepository] 规则解析失败，回退出厂数据: ${e}`);
      return defaultRules();
    }
  }

  private parseDevices(text: string): Device[] {
    if (text.length === 0) {
      return defaultDevices();
    }
    try {
      const list: Device[] = JSON.parse(text) as Device[];
      if (!Array.isArray(list) || list.length === 0) {
        return defaultDevices();
      }
      return list;
    } catch (e) {
      console.error(`[RuleRepository] 设备解析失败: ${e}`);
      return defaultDevices();
    }
  }

  private parseEnv(text: string): EnvState {
    if (text.length === 0) {
      return defaultEnv();
    }
    try {
      const env: EnvState = JSON.parse(text) as EnvState;
      if (env.temperature === undefined) {
        return defaultEnv();
      }
      return env;
    } catch (e) {
      console.error(`[RuleRepository] 环境解析失败: ${e}`);
      return defaultEnv();
    }
  }

  private parseLogs(text: string): LogEntry[] {
    if (text.length === 0) {
      return [];
    }
    try {
      const list: LogEntry[] = JSON.parse(text) as LogEntry[];
      if (!Array.isArray(list)) {
        return [];
      }
      return list.slice(0, MAX_LOG_COUNT);
    } catch (e) {
      console.error(`[RuleRepository] 日志解析失败: ${e}`);
      return [];
    }
  }

  private parseScenarios(text: string): Scenario[] {
    if (text.length === 0) {
      return defaultScenarios();
    }
    try {
      const list: Scenario[] = JSON.parse(text) as Scenario[];
      if (!Array.isArray(list) || list.length === 0) {
        return defaultScenarios();
      }
      return list;
    } catch (e) {
      console.error(`[RuleRepository] 场景解析失败: ${e}`);
      return defaultScenarios();
    }
  }

  async saveRules(rules: Rule[]): Promise<void> {
    await this.store.writeString(KEY_RULES, JSON.stringify(rules));
  }

  async saveDevices(devices: Device[]): Promise<void> {
    await this.store.writeString(KEY_DEVICES, JSON.stringify(devices));
  }

  async saveEnv(env: EnvState): Promise<void> {
    await this.store.writeString(KEY_ENV, JSON.stringify(env));
  }

  async saveLogs(logs: LogEntry[]): Promise<void> {
    await this.store.writeString(KEY_LOGS, JSON.stringify(logs.slice(0, MAX_LOG_COUNT)));
  }

  async saveScenarios(scenarios: Scenario[]): Promise<void> {
    await this.store.writeString(KEY_SCENARIOS, JSON.stringify(scenarios));
  }

  async saveVersion(): Promise<void> {
    await this.store.writeString(KEY_VERSION, `${SCHEMA_VERSION}`);
  }

  /** 一次写入整份快照 */
  async saveAll(snapshot: AppSnapshot): Promise<void> {
    await this.saveRules(snapshot.rules);
    await this.saveDevices(snapshot.devices);
    await this.saveEnv(snapshot.env);
    await this.saveLogs(snapshot.logs);
    await this.saveScenarios(snapshot.scenarios);
    await this.saveVersion();
  }

  /** 清库，回到出厂状态 */
  async resetToFactory(): Promise<AppSnapshot> {
    await this.store.clearAll();
    const fresh: AppSnapshot = {
      rules: defaultRules(),
      devices: defaultDevices(),
      env: defaultEnv(),
      logs: [],
      scenarios: defaultScenarios()
    };
    await this.saveAll(fresh);
    return fresh;
  }
}
