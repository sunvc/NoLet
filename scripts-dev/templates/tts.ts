// 语音脚本（tts）：call 为文本时调用在线 TTS 接口合成音频，返回音频字节。
// App 内测试参数：{ call: "Hello World!" }
export default async function tts(p: TTSParams): Promise<Uint8Array> {
  const text = p.call || "你有新消息";
  const res = await fetch("https://your-tts.example.com/synthesize", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ text, voice: "zh-CN" }),
  });
  if (!res.ok) throw new Error("tts failed: " + res.status);
  // 返回系统可识别的音频格式字节（MP3 等），时长上限约 30 秒

  return new Uint8Array(await res.arrayBuffer());
}

