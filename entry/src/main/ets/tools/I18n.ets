import { common } from '@kit.AbilityKit';

// 非组件上下文（toast/弹窗/扩展进程）取本地化字符串。
// 静态文本直接在组件里用 $r('app.string.xxx')，带占位符和动态文本用本工具按名字查。

// 历史版本落库/下发过的默认分组名，跨语言兼容识别
const LEGACY_DEFAULT_GROUPS: string[] = ['默认', 'Default'];
// 快捷发送消息归入的分组：规范值中文，跨语言兼容识别英文名
const QUICK_GROUPS: string[] = ['快捷消息', 'Quick Message'];

export function resByName(context: common.Context, name: string, ...args: Array<string | number>): string {
  try {
    return context.resourceManager.getStringByNameSync(name, ...args);
  } catch {
    return name;
  }
}

// 默认分组名，跟随当前系统语言（中文「默认」/ 英文「Default」）
export function defaultGroup(context: common.Context): string {
  return resByName(context, 'default_group');
}

// 分组显示名：当前语言默认分组及历史值（'默认'/'Default'）统一映射成本地化名称，其他分组原样
export function displayGroup(context: common.Context, group: string): string {
  const localized: string = defaultGroup(context);
  if (group === localized || LEGACY_DEFAULT_GROUPS.indexOf(group) >= 0) return localized;
  if (QUICK_GROUPS.indexOf(group) >= 0) return resByName(context, 'quick_group');
  return group;
}
