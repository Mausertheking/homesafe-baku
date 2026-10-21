import { GoogleGenAI } from '@google/genai';

import { GEMINI_API_KEY, GEMINI_MODEL } from './config.js';

export interface GeminiRequest {
  systemInstruction: string;
  text: string;
  photo?: { mimeType: string; data: string } | null;
  temperature?: number;
}

/**
 * Thin wrapper so tests can replace Gemini. The key is read from the secret
 * at call time and never logged, returned or stored.
 */
export type GeminiCaller = (req: GeminiRequest) => Promise<string>;

export const callGemini: GeminiCaller = async (req) => {
  const ai = new GoogleGenAI({ apiKey: GEMINI_API_KEY.value() });
  const parts: ({ text: string } | { inlineData: { mimeType: string; data: string } })[] = [{ text: req.text }];
  if (req.photo) parts.push({ inlineData: req.photo });
  const response = await ai.models.generateContent({
    model: GEMINI_MODEL.value(),
    contents: [{ role: 'user', parts }],
    config: {
      systemInstruction: req.systemInstruction,
      temperature: req.temperature ?? 0.3,
      // Thinking tokens count towards maxOutputTokens, and Azerbaijani and
      // Russian need more tokens than English: with 1024 answers were cut off.
      maxOutputTokens: 4096,
      thinkingConfig: { thinkingBudget: 1024 },
    },
  });
  return response.text ?? '';
};
