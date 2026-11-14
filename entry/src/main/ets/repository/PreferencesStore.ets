/**
 * Preferences 轻封装：只负责字符串键值的读写与落盘。
 * 业务层不直接接触 preferences API，方便后续替换为 RDB。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE_NAME: string = 'smart_dorm_lab';

export class PreferencesStore {
  private static instance: PreferencesStore | undefined = undefined;
  private pref: preferences.Preferences | undefined = undefined;

  static get(): PreferencesStore {
    if (PreferencesStore.instance === undefined) {
      PreferencesStore.instance = new PreferencesStore();
    }
    return PreferencesStore.instance;
  }

  get ready(): boolean {
    return this.pref !== undefined;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.pref !== undefined) {
      return;
    }
    const options: preferences.Options = { name: STORE_NAME };
    this.pref = await preferences.getPreferences(context, options);
  }

  async readString(key: string): Promise<string> {
    if (this.pref === undefined) {
      return '';
    }
    const value: preferences.ValueType = await this.pref.get(key, '');
    if (typeof value === 'string') {
      return value;
    }
    return '';
  }

  async writeString(key: string, value: string): Promise<void> {
    if (this.pref === undefined) {
      return;
    }
    await this.pref.put(key, value);
    await this.pref.flush();
  }

  async clearAll(): Promise<void> {
    if (this.pref === undefined) {
      return;
    }
    await this.pref.clear();
    await this.pref.flush();
  }
}
