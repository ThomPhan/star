import { LightningElement, track } from 'lwc';
import getSalesCompWithApprovalHistory from '@salesforce/apex/SalesCompReportController.getSalesCompWithApprovalHistory';
import getSalesCompWithApprovalHistoryFiltered from '@salesforce/apex/SalesCompReportController.getSalesCompWithApprovalHistoryFiltered';
import { NavigationMixin } from 'lightning/navigation';

export default class SalesCompReportLWC extends NavigationMixin(LightningElement){

    @track salesComps;  
    @track error;
    steps;
    clickedButtonLabel;
    searchKey = '';

    connectedCallback(){
        getSalesCompWithApprovalHistory().then(result => {  
            this.salesComps = result;
            this.salesComps.forEach(element => {
                console.log('processSteps: ', element.ProcessSteps);
                this.steps = element.ProcessSteps;
            });  
            

        })  
        .catch(error => {   
            this.error = error; 
            console.log('error:'+this.error); 
        });
    }

    renderedCallback(){
        
    }

    handleSearch(event) {
        //this.clickedButtonLabel = event.target.label;
        //console.log('Button Click:'+this.clickedButtonLabel);
        console.log("PASS HERE");
        console.log(event.target.value);
        this.searchKey = event.target.value;

        if(this.searchKey){
            if(event.keyCode === 13){

                getSalesCompWithApprovalHistoryFiltered({
                    keyValue : this.searchKey
                }).then(result => {  
                    this.salesComps = result;
                    this.salesComps.forEach(element => {
                        console.log('processSteps: ', element.ProcessSteps);
                        this.steps = element.ProcessSteps;
                    });  
                })  
                .catch(error => {   
                    this.error = error; 
                    console.log('error:'+this.error); 
                });
            }
        }else{
            getSalesCompWithApprovalHistory().then(result => {  
                this.salesComps = result;
                this.salesComps.forEach(element => {
                    console.log('processSteps: ', element.ProcessSteps);
                    this.steps = element.ProcessSteps;
                });  
            })  
            .catch(error => {   
                this.error = error; 
                console.log('error:'+this.error); 
            });
        }
    }

    handleKeyChange(event) {  
        this.searchKey = event.target.value;
        console.log('Key Change:'+this.searchKey);
    }      

    // downloadCSV() {
    //     const csv = this.convertToCSV(this.salesComps);
    //     const uri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
    //     window.open(uri, 'exported_records.csv');
    // }

    // convertToCSV(records) {
    //     const header = Object.keys(records[0]).join(',');
    //     const rows = records.map(record => Object.values(record).join(','));
    //     return `${header}\n${rows.join('\n')}`;
    // }

    downloadCSV() {   
        let rowEnd = '\n';
        let csvString = '';
        // this set elminates the duplicates if have any duplicate keys
        let rowData = new Set();

        console.log(this.salesComps);

        // getting keys from data
        this.salesComps.forEach(function (record) {
            //console.log(record);
            //console.log('!@!@!@' + record.ProcessSteps[0].StepStatus); //Usable
            // Object.keys(record).forEach(function (key) {
            //     rowData.add(key);
            // });
            rowData.add('Sales Comp Name');
            rowData.add('Patron Id');
            rowData.add('First Name');
            rowData.add('Last Name');
            rowData.add('Loyalty Program');
            rowData.add('Tier');
            rowData.add('Status');
            rowData.add('Adjustment');
            rowData.add('Comp Type');
            rowData.add('Amount');
            rowData.add('Property');
            rowData.add('Description');
            rowData.add('Owner');
            rowData.add('Comments');
            rowData.add('Additional Comments');
            rowData.add('Created By');
            rowData.add('Created Date');
            rowData.add('Last Modified By');
            rowData.add('Last Modified Date');
            rowData.add('Approval Process History');
        });

        // Array.from() method returns an Array object from any object with a length property or an iterable object.
        rowData = Array.from(rowData);
        console.log('@@@' + rowData);

        // splitting using ','
        csvString += rowData.join(',');
        csvString += rowEnd;

        // main for loop to get the data based on key value
        for(let i=0; i < this.salesComps.length; i++){
            let colValue = 0;
            let tempRow = '';
            // validating keys in data
            // for(let key in rowData) {
            //     if(rowData.hasOwnProperty(key)) {
            //         // Key value 
            //         // Ex: Id, Name
            //         let rowKey = rowData[key];
            //         console.log('rowKey ' + rowKey);
            //         // add , after every value except the first.
            //         if(colValue > 0){
            //             csvString += ',';
            //         }
            //         // If the column is undefined, it as blank in the CSV file.
            //         console.log('123: ' + this.salesComps[i].Owner.Name);
            //         console.log('123: ' + this.salesComps[i].key);
            //         console.log(rowKey);
            //         let value = this.salesComps[i][rowKey] === undefined ? '' : this.salesComps[i][rowKey];
            //         console.log(value);
            //         csvString += '"'+ value +'"';
            //         colValue++;
            //     }
            // }
            // csvString += rowEnd;
            tempRow += this.salesComps[i].Name === undefined ? ',' : this.salesComps[i].Name + ',';
            tempRow += this.salesComps[i].Contact__r.Patron_ID__c === undefined ? ',' : this.salesComps[i].Contact__r.Patron_ID__c + ',';
            tempRow += this.salesComps[i].Contact__r.FirstName === undefined ? ',' : this.salesComps[i].Contact__r.FirstName + ',';
            tempRow += this.salesComps[i].Contact__r.LastName === undefined ? ',' : this.salesComps[i].Contact__r.LastName + ',';
            tempRow += this.salesComps[i].Contact__r.Loyalty_Program__c === undefined ? ',' : this.salesComps[i].Contact__r.Loyalty_Program__c + ',';
            tempRow += this.salesComps[i].Contact__r.Tier__c === undefined ? ',' : this.salesComps[i].Contact__r.Tier__c + ',';
            tempRow += this.salesComps[i].Status__c === undefined ? ',' : this.salesComps[i].Status__c + ',';
            tempRow += this.salesComps[i].Adjustment_Type__c === undefined ? ',' : this.salesComps[i].Adjustment_Type__c + ',';
            tempRow += this.salesComps[i].Comp_Type__c === undefined ? ',' : this.salesComps[i].Comp_Type__c + ',';
            tempRow += this.salesComps[i].Amount__c === undefined ? ',' : this.salesComps[i].Amount__c + ',';
            tempRow += this.salesComps[i].Property__c === undefined ? ',' : this.salesComps[i].Property__c + ',';
            tempRow += this.salesComps[i].Description__c === undefined ? ',' : this.salesComps[i].Description__c + ',';
            tempRow += this.salesComps[i].Owner.Name === undefined ? ',' : this.salesComps[i].Owner.Name + ',';
            tempRow += this.salesComps[i].Comments__c === undefined ? ',' : this.salesComps[i].Comments__c + ',';
            tempRow += this.salesComps[i].Additional_Comments__c === undefined ? ',' : this.salesComps[i].Additional_Comments__c + ',';
            tempRow += this.salesComps[i].CreatedBy.Name === undefined ? ',' : this.salesComps[i].CreatedBy.Name + ',';
            tempRow += this.salesComps[i].CreatedDate === undefined ? ',' : this.salesComps[i].CreatedDate + ',';
            tempRow += this.salesComps[i].LastModifiedBy.Name === undefined ? ',' : this.salesComps[i].LastModifiedBy.Name + ',';
            tempRow += this.salesComps[i].LastModifiedDate === undefined ? '' : this.salesComps[i].LastModifiedDate;

            csvString += tempRow;

            console.log('BEFORE FOR LOOP');
            if(this.salesComps[i].ProcessSteps != undefined){

                let tempHeaders = ',';
                tempHeaders += 'Status,';
                tempHeaders += 'Submitted by,';
                tempHeaders += 'Approver,';
                tempHeaders += 'Comments';
                csvString += tempHeaders;
                csvString += rowEnd;

                for(let x=0; x < this.salesComps[i].ProcessSteps.length; x++){

                    let tempRow2 = '';
                    tempRow2 += ',,,,,,,,,,,,,,,,,,,';
                    tempRow2 += this.salesComps[i].ProcessSteps[x].StepStatus === undefined ? ',' : this.salesComps[i].ProcessSteps[x].StepStatus + ',';
                    tempRow2 += this.salesComps[i].ProcessSteps[x].ProcessInstance.SubmittedBy.Name === undefined ? '' : this.salesComps[i].ProcessSteps[x].ProcessInstance.SubmittedBy.Name;
                    tempRow2 += this.salesComps[i].ProcessSteps[x].ProcessInstance.LastActor.Name === undefined ? ',' : this.salesComps[i].ProcessSteps[x].ProcessInstance.LastActor.Name + ',';
                    tempRow2 += this.salesComps[i].ProcessSteps[x].Comments === undefined ? ',' : this.salesComps[i].ProcessSteps[x].Comments + ',';
                    csvString += tempRow2;
                    csvString += rowEnd;
                    console.log('****' + tempRow2);
                }    
            }
            csvString += rowEnd;
        }

        // Creating anchor element to download
        let downloadElement = document.createElement('a');

        // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
        downloadElement.target = '_self';
        // CSV File Name
        downloadElement.download = 'Sales Comp Report.csv';
        // below statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click(); 
        console.log(downloadElement);
    }

    recordClick(event){
        console.log('RECORD CLICKED');
        console.log(event.currentTarget.dataset.id);
        let salesCompId = event.currentTarget.dataset.id;
        // Navigate to the record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: salesCompId,
                objectApiName: "Sales_Comp__c",
                actionName: "view"
            },
        });
    }
}