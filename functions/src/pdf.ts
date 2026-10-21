import PDFDocument from 'pdfkit';

import { TIME_ZONE } from './config.js';
import { PROFILE_VALUE_KEYS, strings } from './i18n.js';
import { assetPath, type Language } from './shared.js';

/**
 * PDF generation. Noto Sans (SIL Open Font License) covers Latin Extended
 * (ə ğ ı ö ü ç ş) and Cyrillic, so Azerbaijani and Russian render correctly.
 * The standard PDF fonts would NOT.
 */
const FONT_REGULAR = assetPath('fonts', 'NotoSans-Regular.ttf');
const FONT_BOLD = assetPath('fonts', 'NotoSans-Bold.ttf');

const LOCALES: Record<Language, string> = { az: 'az-AZ', ru: 'ru-RU', en: 'en-GB' };

export function formatDateTime(date: Date, lang: Language): string {
  return new Intl.DateTimeFormat(LOCALES[lang], {
    dateStyle: 'medium', timeStyle: 'short', timeZone: TIME_ZONE,
  }).format(date);
}

export function formatDate(date: Date, lang: Language): string {
  return new Intl.DateTimeFormat(LOCALES[lang], { dateStyle: 'long', timeZone: TIME_ZONE }).format(date);
}

function newDoc(title: string): PDFKit.PDFDocument {
  const doc = new PDFDocument({ size: 'A4', margin: 50, info: { Title: title, Producer: 'HomeSafe', Creator: 'HomeSafe' } });
  doc.registerFont('regular', FONT_REGULAR);
  doc.registerFont('bold', FONT_BOLD);
  doc.font('regular');
  return doc;
}

function toBuffer(doc: PDFKit.PDFDocument): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    doc.on('data', (c: Buffer) => chunks.push(c));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
    doc.end();
  });
}

function heading(doc: PDFKit.PDFDocument, text: string, size = 15) {
  doc.moveDown(0.8).font('bold').fontSize(size).fillColor('#123').text(text).font('regular').fontSize(11).fillColor('#000');
  doc.moveDown(0.3);
}

function ensureSpace(doc: PDFKit.PDFDocument, needed: number) {
  if (doc.y + needed > doc.page.height - doc.page.margins.bottom) doc.addPage();
}

// ---------------------------------------------------------------- report

export interface ReportProfile {
  role?: string | null;
  district?: string | null;
  buildingAgeBand?: string | null;
  heatingType?: string | null;
  heaterLocation?: string | null;
  hasCoAlarm?: string | null;
  hasWrittenContract?: boolean | null;
}

export interface ReportCheck {
  hazard: string; // gas_co | damp_mold
  resultLevel: string; // red | amber | green
  matchedRuleIds: string[];
  reasonKeys: string[];
  rulesVersion: number;
  createdAt: Date;
}

export interface ReportEvidence {
  id: string;
  type: string;
  text: string;
  sha256?: string | null;
  serverTime?: Date | null;
  photo?: Buffer | null;
}

export interface ReportInput {
  lang: Language;
  generatedAt: Date;
  from: Date;
  to: Date;
  profile: ReportProfile;
  checks: ReportCheck[];
  evidence: ReportEvidence[];
}

const LEVEL_KEYS: Record<string, string> = { red: 'levelRed', amber: 'levelAmber', green: 'levelGreen' };
const LEVEL_COLORS: Record<string, string> = { red: '#C62828', amber: '#B26A00', green: '#2E7D32' };
const CHECK_KEYS: Record<string, string> = { gas_co: 'checkGasTitle', damp_mold: 'checkDampTitle' };
const EVIDENCE_KEYS: Record<string, string> = {
  photo: 'evidenceTypePhoto', note: 'evidenceTypeNote', symptom: 'evidenceTypeSymptom',
  check: 'evidenceTypeCheck', letter: 'evidenceTypeLetter',
};

export async function buildReportPdf(input: ReportInput): Promise<Buffer> {
  const t = strings(input.lang);
  const doc = newDoc(t('report.title'));

  doc.font('bold').fontSize(22).text(t('report.title'));
  doc.font('regular').fontSize(11).fillColor('#444')
    .text(t('report.generated', { date: formatDateTime(input.generatedAt, input.lang) }))
    .text(t('report.period', { from: formatDate(input.from, input.lang), to: formatDate(input.to, input.lang) }))
    .fillColor('#000');

  // Home profile
  heading(doc, t('report.section.home'));
  const p = input.profile;
  const value = (field: keyof typeof PROFILE_VALUE_KEYS, v?: string | null) =>
    v ? t(PROFILE_VALUE_KEYS[field]?.[v] ?? v) : '—';
  const rows: [string, string][] = [
    [t('profileRole'), value('role', p.role)],
    [t('profileDistrict'), p.district ? t(`district.${p.district}`) : '—'],
    [t('profileBuildingAge'), value('buildingAgeBand', p.buildingAgeBand)],
    [t('profileHeating'), value('heatingType', p.heatingType)],
    [t('profileWaterHeater'), value('heaterLocation', p.heaterLocation)],
    [t('profileCoAlarm'), value('hasCoAlarm', p.hasCoAlarm)],
  ];
  if (p.role === 'renter') {
    rows.push([t('profileContract'), p.hasWrittenContract == null ? '—' : t(p.hasWrittenContract ? 'yes' : 'no')]);
  }
  for (const [label, v] of rows) {
    doc.font('bold').text(`${label} `, { continued: true }).font('regular').text(v);
  }

  // Checks
  heading(doc, t('report.section.checks'));
  if (input.checks.length === 0) doc.text(t('report.no_items'));
  for (const c of input.checks) {
    ensureSpace(doc, 80);
    doc.font('bold').fillColor(LEVEL_COLORS[c.resultLevel] ?? '#000')
      .text(`${t(CHECK_KEYS[c.hazard] ?? c.hazard)}: ${t(LEVEL_KEYS[c.resultLevel] ?? c.resultLevel)}`)
      .fillColor('#000').font('regular').fontSize(10)
      .text(`${formatDateTime(c.createdAt, input.lang)} · ${t('report.rules_version', { version: c.rulesVersion })}`)
      .fontSize(11);
    for (const key of c.reasonKeys) doc.text(`• ${t(key)}`, { indent: 10 });
    doc.moveDown(0.5);
  }

  // Evidence
  heading(doc, t('report.section.evidence'));
  if (input.evidence.length === 0) doc.text(t('report.no_items'));
  for (const e of input.evidence) {
    ensureSpace(doc, e.photo ? 330 : 90);
    doc.font('bold').text(t(EVIDENCE_KEYS[e.type] ?? e.type)).font('regular').fontSize(10);
    doc.text(e.serverTime
      ? `${t('report.field.recorded')}: ${formatDateTime(e.serverTime, input.lang)}`
      : t('report.field.not_verified'));
    doc.text(`${t('report.field.hash')}: ${e.sha256 ?? t('report.field.not_verified')}`);
    doc.fontSize(11);
    if (e.photo) {
      try {
        doc.moveDown(0.3).image(e.photo, { fit: [360, 260] });
      } catch {
        // Unsupported image format: keep the hash and time, skip the picture.
      }
    }
    if (e.text) doc.moveDown(0.2).text(e.text);
    doc.moveDown(0.8);
  }

  // How the hashes work (the footer the brief asks for) + disclaimer.
  ensureSpace(doc, 160);
  doc.moveDown(1).strokeColor('#999').moveTo(doc.page.margins.left, doc.y)
    .lineTo(doc.page.width - doc.page.margins.right, doc.y).stroke();
  doc.moveDown(0.5).fontSize(9).fillColor('#333').text(t('report.footer'));
  doc.moveDown(0.5).text(t('report.disclaimer'));
  return toBuffer(doc);
}

// ---------------------------------------------------------------- letter

export async function buildLetterPdf(lang: Language, body: string): Promise<Buffer> {
  const t = strings(lang);
  const doc = newDoc(t('letter.pdf.title'));
  doc.fontSize(12).text(body, { lineGap: 3 });
  return toBuffer(doc);
}
