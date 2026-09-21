// @keepTs
// @ts-nocheck
import { CodeTheme } from '../constant/CodeTheme';
export type MermaidTheme = "default" | "dark" | "forest" | "neutral";
export type MermaidSecurityLevel = "strict" | "loose" | "antiscript" | "sandbox";
export declare function buildMermaidHtml(i117: Context, j117: string, k117: MermaidTheme, l117: MermaidSecurityLevel, m117?: CodeTheme): Promise<string>;
export declare function buildMermaidMissingHtml(c117?: CodeTheme): string;
