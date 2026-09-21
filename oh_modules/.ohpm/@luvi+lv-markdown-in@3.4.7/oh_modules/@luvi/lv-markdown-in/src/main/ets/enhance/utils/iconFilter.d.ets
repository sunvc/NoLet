// @keepTs
// @ts-nocheck
import drawing from "@ohos.graphics.drawing";
/**
 * 按主题 token（如 {@link AppTheme.menuBarIconTint}）生成图标着色滤镜，用于 `Image.colorFilter(...)`。
 * - tint 为非空颜色（`#RRGGBB`）：用 SRC_IN 把图标整片染成该色，保留原图 alpha 形状
 * - tint 为空串：返回 DST 恒等滤镜（结果取原图、忽略源色），等价于不加滤镜，
 *   这样调用方可以无条件地 `.colorFilter(iconColorFilter(...))`，不必处理 undefined
 */
export declare function iconColorFilter(y110: string): drawing.ColorFilter;
