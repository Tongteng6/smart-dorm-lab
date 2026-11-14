/**
 * 全局状态容器（ViewModel 层）。
 * 页面只与本类交互：读快照、发起变更；副作用（重算 / 落盘）集中在这里。
 */
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { MAX_LOG_COUNT } from '../common/Constants';
import { Device } from '../model/Device';
import { EnvState, clampEnv, defaultEnv } from '../model/EnvState';
import { LogEntry } from '../model/LogEntry';
import { Rule } from '../model/Rule';
import { Scenario, newScenarioId } from '../model/Scenario';
import { AppSnapshot, RuleRepository } from '../repository/RuleRepository';
import { PreferencesStore } from '../repository/PreferencesStore';
import { EvaluationResult, buildLog, evaluate } from '../engine/RuleEngine';

export class DormStore {
  private static instance: DormStore | undefined = undefined;

  rules: Rule[] = [];
  devices: Device[] = [];
  env: EnvState = defaultEnv();
  logs: LogEntry[] = [];
  scenarios: Scenario[] = [];
  ready: boolean = false;
  lastResult: EvaluationResult | undefined = undefined;

  private repo: RuleRepository = new RuleRepository();

  static get(): DormStore {
    if (DormStore.instance === undefined) {
      DormStore.instance = new DormStore();
    }
    return DormStore.instance;
  }

  /** 应用启动时调用一次：读盘 + 首次计算 */
  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.ready) {
      return;
    }
    await PreferencesStore.get().init(context);
    const snapshot: AppSnapshot = await this.repo.loadAll();
    this.rules = snapshot.rules;
    this.devices = snapshot.devices;
    this.env = clampEnv(snapshot.env);
    this.logs = snapshot.logs;
    this.scenarios = snapshot.scenarios;
    this.ready = true;
    // 启动即计算，保证界面与规则一致（需求 3.4）
    this.compute(false);
    await this.persist();
  }

  /** 只重算，不落盘 */
  compute(forceLog: boolean): EvaluationResult {
    const result: EvaluationResult = evaluate(this.env, this.rules, this.devices);
    this.devices = result.nextDevices;
    this.lastResult = result;
    const changed: boolean = result.steps.some((s) => s.status === 'applied');
    if (changed || forceLog) {
      const entry: LogEntry = buildLog(this.env, result);
      this.logs = [entry].concat(this.logs).slice(0, MAX_LOG_COUNT);
    }
    return result;
  }

  async setEnv(next: EnvState): Promise<void> {
    this.env = clampEnv(next);
    this.compute(false);
    await this.persist();
  }

  /** 拖动滑块时的实时预览：只重算不落盘，避免高频写盘 */
  previewEnv(next: EnvState): void {
    this.env = clampEnv(next);
    this.compute(false);
  }

  /** 「立即执行」：强制产生一条日志 */
  async runOnce(): Promise<void> {
    this.compute(true);
    await this.persist();
  }

  async applyScenario(scenarioId: string): Promise<void> {
    const found: Scenario | undefined = this.scenarios.find((s: Scenario) => s.id === scenarioId);
    if (found === undefined) {
      return;
    }
    this.env = clampEnv(found.env);
    this.compute(true);
    await this.persist();
  }

  async saveScenario(name: string): Promise<void> {
    const trimmed: string = name.trim();
    if (trimmed.length === 0) {
      return;
    }
    const scenario: Scenario = {
      id: newScenarioId(),
      name: trimmed,
      icon: '📍',
      env: this.env
    };
    this.scenarios = this.scenarios.concat([scenario]);
    await this.persist();
  }

  async deleteScenario(id: string): Promise<void> {
    if (this.scenarios.length <= 1) {
      return;
    }
    this.scenarios = this.scenarios.filter((s: Scenario) => s.id !== id);
    await this.persist();
  }

  /** 新增或更新规则；更新按 id 覆盖 */
  async upsertRule(rule: Rule): Promise<void> {
    const exists: boolean = this.rules.some((r: Rule) => r.id === rule.id);
    if (exists) {
      this.rules = this.rules.map((r: Rule) => r.id === rule.id ? rule : r);
    } else {
      this.rules = this.rules.concat([rule]);
    }
    this.compute(true);
    await this.persist();
  }

  async toggleRule(id: string): Promise<void> {
    this.rules = this.rules.map((r: Rule) => {
      if (r.id !== id) {
        return r;
      }
      const copy: Rule = {
        id: r.id,
        name: r.name,
        enabled: !r.enabled,
        priority: r.priority,
        logic: r.logic,
        conditions: r.conditions,
        actions: r.actions,
        createdAt: r.createdAt
      };
      return copy;
    });
    this.compute(true);
    await this.persist();
  }

  async deleteRule(id: string): Promise<void> {
    this.rules = this.rules.filter((r: Rule) => r.id !== id);
    this.compute(true);
    await this.persist();
  }

  async clearLogs(): Promise<void> {
    this.logs = [];
    await this.persist();
  }

  async resetAll(): Promise<void> {
    const fresh: AppSnapshot = await this.repo.resetToFactory();
    this.rules = fresh.rules;
    this.devices = fresh.devices;
    this.env = fresh.env;
    this.logs = fresh.logs;
    this.scenarios = fresh.scenarios;
    this.compute(false);
    await this.persist();
  }

  lastLog(): LogEntry | undefined {
    return this.logs.length > 0 ? this.logs[0] : undefined;
  }

  private async persist(): Promise<void> {
    try {
      await this.repo.saveAll({
        rules: this.rules,
        devices: this.devices,
        env: this.env,
        logs: this.logs,
        scenarios: this.scenarios
      });
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error(`[DormStore] 持久化失败: ${err.code} ${err.message}`);
    }
  }
}
