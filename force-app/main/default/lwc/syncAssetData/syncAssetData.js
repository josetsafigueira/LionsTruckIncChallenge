import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import syncWorkshopData from '@salesforce/apex/SyncAssetDataController.syncWorkshopData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ASSET_SERIAL_NUMBER from '@salesforce/schema/Asset.SerialNumber';
import ASSET_NAME from '@salesforce/schema/Asset.Name';

export default class SyncAssetData extends LightningElement {
    @api recordId;
    serialNumber;
    message;
    isLoading = true;
    synced = false;
    
    @wire(getRecord, {recordId: '$recordId', fields:[ASSET_NAME, ASSET_SERIAL_NUMBER]})
    getAsset({error, data}) {
        if (data) {
            if (data.fields.SerialNumber.value) {
                this.serialNumber = data.fields.SerialNumber.value;
                this.message = `Press Submit to sync the vehicle ${this.serialNumber} with workshop data`;
            } else {
                this.message = 'This asset does not have a serial Number';
            }
        } else if (error) {
            console.log(JSON.stringify(error));
            this.message = 'An error occurred';
        }
        this.isLoading = false;
    }

    get disableSubmitButton() {
        return !this.serialNumber || this.synced;
    }

    syncAssetWithWorshop() {
        console.log('IN function');
        console.log(this.serialNumber);
        if (this.serialNumber) {
            this.isLoading = true;
            syncWorkshopData({ vin: this.serialNumber, assetId: this.recordId})
            .then(result => {
                this.synced = true;
                this.showToastNotification('success', 'Please Refresh the page.', 'Asset Synced Successfully!');
            })
            .catch(error => {
                this.message = error.body.message;
                this.showToastNotification('error', 'error.body.message', 'An error occurred while syncing the asset');
                console.log(JSON.stringify(error));
            })
            .finally(() => {
                this.isLoading = false;
            })
        }
    }

    showToastNotification(type, title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        }));
    }
}