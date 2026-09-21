// @keepTs
// @ts-nocheck
import { MarkdownPlugin } from '../model/MarkdownPlugin';
export declare class MarkdownPluginRegistry {
    private static pluginMap;
    static registerPlugins(i59: string, j59: MarkdownPlugin[]): void;
    static getPlugin(g59: string, h59: string): MarkdownPlugin | undefined;
    static destroy(f59: string): void;
}
