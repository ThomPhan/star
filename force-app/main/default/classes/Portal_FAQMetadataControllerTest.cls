@isTest
public class Portal_FAQMetadataControllerTest {

    @isTest
    static void testGetCodeTitleMap() {
        // Call the Apex method
        Test.startTest();
        Map<String, String> resultMap = Portal_FAQMetadataController.getCodeTitleMap();
        Test.stopTest();

        // Validate that the results contain the correct mappings
        System.assertEquals(3, resultMap.size(), 'There should be exactly 3 entries in the map.');
        System.assertEquals('Player Card', resultMap.get('faq-player-card'), 'Mapping for Player Card is incorrect.');
        System.assertEquals('Digital Card', resultMap.get('faq-player-card-digital-card'), 'Mapping for Digital Card is incorrect.');
        System.assertEquals('Player Activity Statement', resultMap.get('faqs---pas'), 'Mapping for Player Activity Statement is incorrect.');
    }
}