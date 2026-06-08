import { LightningElement, api } from 'lwc';

const LOCALE_OPTIONS = [
    { label: 'English (US)', value: 'en_US' },
    { label: 'Spanish (Mexico)', value: 'es_MX' },
    { label: 'French (France)', value: 'fr_FR' },
    { label: 'German (Germany)', value: 'de_DE' },
    { label: 'Portuguese (Brazil)', value: 'pt_BR' },
    { label: 'Japanese (Japan)', value: 'ja_JP' }
];

export default class IntakeTranslationsEditor extends LightningElement {
    @api translations = [];

    localeOptions = LOCALE_OPTIONS;

    get displayTranslations() {
        return (this.translations || []).map((t, idx) => ({
            ...t,
            uiKey: `t-${idx}`,
            index: idx
        }));
    }

    handleAdd() {
        const used = new Set((this.translations || []).map((t) => t.locale));
        const nextLocale = LOCALE_OPTIONS.find((o) => !used.has(o.value))?.value || 'en_US';
        const next = [
            ...(this.translations || []),
            { locale: nextLocale, questionText: '', helpText: '' }
        ];
        this.fireChange(next);
    }

    handleDelete(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const next = (this.translations || []).filter((_, i) => i !== idx);
        this.fireChange(next);
    }

    handleField(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const field = event.currentTarget.dataset.field;
        const value = event.detail?.value ?? event.target.value;
        const next = (this.translations || []).map((t, i) =>
            i === idx ? { ...t, [field]: value } : t
        );
        this.fireChange(next);
    }

    fireChange(next) {
        this.dispatchEvent(
            new CustomEvent('translationschange', { detail: { translations: next } })
        );
    }
}
