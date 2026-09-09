// 插件脚本（plugin）：完全接管通知处理。推送携带 plugin 字段（值为脚本名）时触发。
// 不返回 = 接管内置流程；return { continue: true } = 放行并保留修改；
// return { continue: "original" } = 放行并丢弃修改。
export default async function plugin(note: PluginNote): Promise<PluginResult | void> {
  const info = note.userInfo;

  // 1. 自定义解密（失败则回退原始字段）
  let m: Record<string, any> = { title: note.title, body: note.body, group: note.group };
  if (info.ciphertext) {
    try {
      m = await decrypt(info.ciphertext, info.ciphernumber || 0);
    } catch (e) {
      console.error("decrypt failed", e);
    }
  }

  // 2. 改写通知内容
  await setContent({
    title: m.title,
    body: m.body,
    group: m.group || "默认",
    level: info.pinned ? "timesensitive" : "active",
    badge: info.badge,
  });

  // 3. 附件与头像
  if (info.image) await attach({ type: "image", url: info.image });
  if (info.location) await attach({ type: "map", location: info.location });
  if (info.icon) await setAvatar(info.icon);

  // 4. 声音
  if (info.call) {
    await setSound({ tts: m.body });
  } else if (info.sound) {
    await setSound(info.sound);
  }

  // 5. 落库（接管模式下内置流程不自动落库）
  await archive({
    title: m.title,
    subtitle: m.subtitle,
    body: m.body,
    group: m.group,
    url: info.url,
    ttl: info.ttl,
    other: info,
  });
}
