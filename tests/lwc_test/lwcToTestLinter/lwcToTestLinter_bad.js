/**********
* @title Salesforce Easy Checks - Sample JavaScript
* @filename editRecordScreenAction_bad.js
*
* @description JavaScript with linting errors. Intended to test LWC linter. Refer to @source_repo and @source_path for origin.
* @source_repo https://github.com/trailheadapps/lwc-recipes/tree/c7e3dea3db908c11265c1ac8bb2d9e6f651d50dc
* @source_path force-app/main/default/lwc/editRecordScreenAction/editRecordScreenAction.js
**********/


import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/Contact.Id';
import FIRSTNAME_FIELD from '@salesforce/schema/Contact.FirstName';
import LASTNAME_FIELD from '@salesforce/schema/Contact.LastName';

export default class EditRecordScreenAction extends LightningElement {
    @api recordId;
    @api objectApiName;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [FIRSTNAME_FIELD, LASTNAME_FIELD]
    })
    contact;

    get firstname() {
        return this.contact.data
            ? this.contact.data.fields.FirstName.value
            : null;
    }

    get lastname() {
        return this.contact.data
            ? this.contact.data.fields.LastName.value
            : null;
    }

    handleSave() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[FIRSTNAME_FIELD.fieldApiName] = this.template.querySelector(
            "[data-field='FirstName']"
        ).value;
        fields[LASTNAME_FIELD.fieldApiName] = this.template.querySelector(
            "[data-field='LastName']"
        ).value;
        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Contact updated',
                        variant: 'success'
                    })
                );

                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record, try again...',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    /**
    * @description New function with linting errors. Added to test LWC linter. See @link for origin.
    * @link https://eslint.org/docs/user-guide/formatters/
    * @param {number} i - Number to increase by one.
    */
    addOne(i) {
        if (i != NaN) {
            return i ++
        } else {
          return
        }
    }

}
