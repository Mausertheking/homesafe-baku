#!/usr/bin/env python3
"""Add, update or remove keys in the app ARB files (az/ru/en) in one go.

Usage from Python:  from arb_edit import edit; edit(add={...}, remove=[...])
add = { key: (en, az, ru) }  or  { key: (en, az, ru, {"placeholder": "String"}) }
"""
import json, os, sys

APP = os.path.join(os.path.dirname(__file__), '..', 'app')
FILES = {'en': 'lib/l10n/app_en.arb', 'az': 'lib/l10n/app_az.arb', 'ru': 'lib/l10n/app_ru.arb'}
CONTENT = {'en': 'assets/l10n/content_en.arb', 'az': 'assets/l10n/content_az.arb', 'ru': 'assets/l10n/content_ru.arb'}
ORDER = ['en', 'az', 'ru']

def edit(add=None, remove=(), content=False):
    files = CONTENT if content else FILES
    for i, lang in enumerate(ORDER):
        path = os.path.join(APP, files[lang])
        data = json.load(open(path, encoding='utf-8'))
        for k in remove:
            data.pop(k, None); data.pop('@' + k, None)
        for k, v in (add or {}).items():
            data[k] = v[i]
            if lang == 'en' and not content:
                meta = {'description': k}
                if len(v) > 3:
                    meta['placeholders'] = {p: {'type': t} for p, t in v[3].items()}
                data['@' + k] = meta
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2); f.write('\n')
