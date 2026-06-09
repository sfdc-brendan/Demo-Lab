import { api, LightningElement } from 'lwc';

export default class HighlightCard extends LightningElement {
    _value;
    _readOnly = false;

    @api
    get value() {
        return this._value;
    }
    set value(newValue) {
        this._value = newValue || {};
    }

    @api
    get readOnly() {
        return this._readOnly;
    }
    set readOnly(flag) {
        this._readOnly = flag;
    }

    get title() {
        return this._value?.title;
    }

    get description() {
        return this._value?.description;
    }

    get imageUrl() {
        return this._value?.imageUrl;
    }

    get linkUrl() {
        return this._value?.linkUrl;
    }

    get resolvedLinkLabel() {
        return this._value?.linkLabel || 'Learn more';
    }
}
