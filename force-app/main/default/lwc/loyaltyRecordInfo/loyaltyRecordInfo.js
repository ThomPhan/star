import { LightningElement, api, wire, track } from 'lwc';
import getLoyaltyRecord from '@salesforce/apex/LoyaltyHelper.getLoyaltyInfo';
import runCallOutSalesConsole from '@salesforce/apex/CompRoomNightDataProvider.runCallOutSalesConsole';

export default class LoyaltyRecordInfo extends LightningElement {
    @api recordId;
    @track childLoyalty;
    @track loyaltyRecId;
    @track loyaltyRecordUrl;
    lastSuccessfulUpdate;
    tempDate;
    compRoomNightEntitlement;
    compRoomNightRemainingForTheYear;
    compRoomNightRemainingForTheMonth;
    compRoomMonthlyBalances = [];

    tierReviewDate;
    tierBalance;
    RetainCurrentTier;
    nextTier;
    pointsEarnedToday;
    pointsEarnedThisWeek;
    pointsEarnedThisMonth;
    casinoBalance;
    compBalance;

    @wire(getLoyaltyRecord, { contactId : '$recordId' })
    loyaltyRec({error, data }) {
        if(data){
            this.childLoyalty = data;
            let tierReviewDateTemp = data.Tier_Review_Date__c.substring(8,10) + '/' + data.Tier_Review_Date__c.substring(5,7) + '/' + data.Tier_Review_Date__c.substring(0,4);
            this.tierReviewDate = tierReviewDateTemp;


            this.tierBalance = data.Tier_Balance__c;
            this.RetainCurrentTier = data.Points_to_Retain_Current_Tier__c;
            this.nextTier = data.Points_To_Next_Tier__c;
            this.pointsEarnedToday = data.Tier_Points_Earned_Today__c;
            this.pointsEarnedThisWeek = data.Tier_Points_Earned_This_Week__c;
            this.pointsEarnedThisMonth = data.Tier_Points_Earned_This_Month__c;
            this.casinoBalance = data.CasinoBalance__c;
            this.compBalance = data.CompBalance__c;

            console.log('data :', JSON.parse(JSON.stringify(data)));
            this.loyaltyRecId = data.Id;
            this.tempDate = new Date(data.Last_Successful_Update__c.substring(0,23));
            this.lastSuccessfulUpdate = this.tempDate.toLocaleString('en-AU');
            this.error = undefined;
            this.loyaltyRecordUrl = window.location.origin + '/lightning/r/Loyalty__c/' + this.loyaltyRecId + '/edit';
            console.log('this.loyaltyRecordUrl :', this.loyaltyRecordUrl);
        }else if(error) {
            this.error = error;
            console.log('this.error :', this.error);
            this.childLoyalty = undefined;
        }
    };

    connectedCallback(){
        runCallOutSalesConsole({ contactId: this.recordId })
            .then((result) => {
                this.compRoomNightEntitlement = result.entitlement;
                this.compRoomNightRemainingForTheYear = result.balance;
                this.compRoomMonthlyBalances = result.monthlyBalances;

                let rightNow = new Date();
                rightNow.setMinutes(new Date().getMinutes() - new Date().getTimezoneOffset());
                let yearToday = rightNow.toISOString().slice(0,4);
                let monthToday = rightNow.toISOString().slice(5,7);
                let currentRemaining = 0;
                let currentUsed = 0;
    
                this.compRoomMonthlyBalances.forEach(myFunction);
                function myFunction(item) {
                    if(item.year == yearToday && item.month == monthToday){ 
                        currentUsed = parseInt(item.used);
                        currentRemaining = parseInt(item.remaining);
    
                    }
                }
                this.compRoomNightRemainingForTheMonth = currentRemaining;

            })
            .catch((error) => {
                this.error = error;
                console.log(error);
            });
    }
}