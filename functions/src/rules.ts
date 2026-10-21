import { readSharedJson } from './shared.js';

/** Minimal view of the bundled rule files (same files the app ships). */
export interface RuleJson {
  id: string;
  hazard: string;
  version: number;
  reviewed?: boolean;
  conditions: unknown;
  result: { level: string; emergency?: boolean; reason_key: string; steps_keys: string[]; category?: string };
}

interface RuleFile {
  check: string;
  rulesVersion: number;
  rules: RuleJson[];
}

let byId: Map<string, RuleJson & { check: string }> | undefined;

export function ruleFiles(): RuleFile[] {
  return [readSharedJson<RuleFile>('rules', 'gas_co.json'), readSharedJson<RuleFile>('rules', 'damp_mold.json')];
}

export function ruleById(id: string): (RuleJson & { check: string }) | undefined {
  byId ??= new Map(ruleFiles().flatMap((f) => f.rules.map((r) => [r.id, { ...r, check: f.check }] as const)));
  return byId.get(id);
}
