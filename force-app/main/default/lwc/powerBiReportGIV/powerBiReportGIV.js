import { LightningElement, api, wire } from 'lwc';
import getEmbeddingDataForReport from '@salesforce/apex/PowerBiEmbedManagerGIV.getEmbeddingDataForReport';
import getMetadataValue from '@salesforce/apex/powerBiReportControllerGIV.getMetadataValue';
import powerbijs from '@salesforce/resourceUrl/powerbijs';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { getRecord } from "lightning/uiRecordApi";

const FIELDS = [
  "Contact.Patron_ID__c"
];

export default class PowerBiReport extends LightningElement {
  properties = [];
  error;
  @api WorkspaceId ='';
  @api ReportId ='';

  @api recordId;

  @api patronId;
    

    @wire(getRecord, { recordId:'$recordId', fields: FIELDS})
    loadFields({error, data}){
        console.log('TRYING TO LOAD FIELDS');
        if(error){
            console.log('@@@' + error);
        }else if(data){
            this.contact = data;
            this.patronId = this.contact.fields.Patron_ID__c.value;
            console.log('@@@ ' + this.patronId);
        }
    }
  
  get containerLarge() {
    switch(FORM_FACTOR) {
      case 'Large':
      return true;
      case 'Small':
      return false;
      default: return true
    }
  }
  get containerSmall() {
    switch(FORM_FACTOR) {
      case 'Large':
      return false;
      case 'Small':
      return true;
      default: return false
    }
  }

  get layoutTypeValue() {
    switch(FORM_FACTOR) {
      case 'Large':
      return 0;
      case 'Small':
      return 2;
      default: return 0
    }
  }
  @wire(getEmbeddingDataForReport,{
    WorkspaceId: "$WorkspaceId",
    ReportId: "$ReportId"
  }) report;

  @wire(getMetadataValue, {})
    wireGetMetadataValue(properties){
      if(properties.data){
        this.properties = properties.data;
        this.WorkspaceId = this.properties[0].Workspace_ID__c;
        this.ReportId = this.properties[0].Report_ID__c;
      }
      else if(properties.error){
        this.error = properties.error;
        console.log('Error: ' + this.error);
      }
    }

    renderedCallback() {
       console.log('renderedCallback executing');

        Promise.all([ loadScript(this, powerbijs ) ]).then(() => { 

          console.log('renderedCallback 2');
          console.log("this.report", this.report);

          const basicFilter = {
            $schema: "http://powerbi.com/product/schema#basic",
            target: {
            table: "dim_Customer",
            column: "Patron ID"
            },
            operator: "Is",
            values: [this.patronId],
            filterType: 1
            }; 

            if(this.report.data){

              if(this.report.data.embedUrl && this.report.data.embedToken){
                var reportContainer = this.template.querySelector('[data-id="embed-container"');

                var reportId = this.report.data.reportId;
                var embedUrl = this.report.data.embedUrl;
                var token = this.report.data.embedToken; 
              
                var config = {
                  type: 'report',
                  id: reportId,
                  embedUrl: embedUrl,
                  accessToken: token,
                  tokenType: 1,
                  filters: [basicFilter], //added
                  settings: {
                    panes: {
                      filters: { expanded: false, visible: false },
                      pageNavigation: { visible: true }
                    },
                    layoutType: this.layoutTypeValue
                  }
                };
              
                // Embed the report and display it within the div container.
                var report = powerbi.embed(reportContainer, config);

                console.log(powerbi);

              }
              else {
                console.log('no embedUrl or embedToken');
              }
                
              }
              else{
                  console.log('no report.data yet');
              }
       

        });

    }

}