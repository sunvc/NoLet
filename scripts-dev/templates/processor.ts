// 处理器脚本（processor）：做副作用，不改通知显示。返回值被忽略。
// 示例：把通知转发到自己的 Webhook。
// App 内测试参数：{ title: "Test", subtitle: "Test", body: "Test" }
export default async function forward(p: ProcessorParams): Promise<void> {
  await fetch("https://your-server.example.com/hook", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      title: p.title,
      body: p.body,
      group: p.group,
      receivedAt: Date.now(),
    }),
  });
}
