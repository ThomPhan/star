import { api, LightningElement } from 'lwc';

export default class NavigateToRecord_LWC extends LightningElement {
  /**
   * Record Id of the record page to which the action should forward.
   * @type {string}
   * @default ''
   */
  @api recordId;

  /**
   * Open the page in the same '_self' or in a new tab '_blank '.
   * @type {string}
   * @default ''
   */
  @api target = '_blank';

  connectedCallback() {
    const completeURL = `${window.location.origin}/${this.recordId}`;
    window.open(completeURL, this.target);
  }
}