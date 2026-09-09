// 动作脚本（action）：用户点击通知上绑定脚本的按钮时执行。
// 用 p.actionmode 区分被点击的按钮；正常结束提示"执行成功"，抛错显示错误信息。
// App 内测试参数：{ actionmode: "custom" }
export default async function handleAction(p: ActionParams): Promise<void> {
  const base = p.reply || "https://your-server.example.com/action";
  switch (p.actionmode) {
    case "approve":
      await fetch(base + "/approve", { method: "POST" });
      break;
    case "reject":
      await fetch(base + "/reject", { method: "POST" });
      break;
    default:
      await fetch(base + "?mode=" + encodeURIComponent(p.actionmode), { method: "POST" });
  }
}
