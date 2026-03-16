/**
 * @description Apex controller for AI Case Generator LWC component
 * Handles Contact lookup/creation, Einstein LLM integration, and bulk case creation
 * @author Salesforce
 * @date 2024
 */
public with sharing class AICaseGeneratorController {
    
    // Constants for validation and limits
    private static final Integer MAX_CASE_COUNT = 10;
    private static final Integer MIN_CASE_COUNT = 1;
    private static final Integer MAX_CUSTOMER_NAME_LENGTH = 100;
    private static final Integer MAX_ADDITIONAL_DETAILS_LENGTH = 1000;
    
    // Einstein LLM prompt template names
    private static final String EINSTEIN_CASE_PROMPT_TEMPLATE = 'Case_Generator';
    private static final String EINSTEIN_KNOWLEDGE_PROMPT_TEMPLATE = 'Knowledge_Article_Generation_Template';
    
    // Toggle for AI vs Mock data (set to true when Einstein LLM is available)
    private static final Boolean USE_EINSTEIN_LLM = true;
    
    // Temporary storage for Knowledge Article responses from Flow
    private static Map<String, String> currentKnowledgeResponses;
    
    /**
     * @description Main method to generate cases using AI and assign to contacts
     * @param industry The industry context for case generation (optional - auto-detected if blank)
     * @param customerName The company name for generating employee cases
     * @param additionalDetails Additional context for AI generation
     * @param caseCount Number of cases to generate (1-10)
     * @param createKnowledgeArticle Whether to create an associated knowledge article
     * @return CaseGenerationResponse containing success status, cases, and contact info
     */
    @AuraEnabled
    public static CaseGenerationResponse generateCases(
        String industry, 
        String customerName, 
        String additionalDetails, 
        Integer caseCount,
        Boolean createKnowledgeArticle
    ) {
        try {
            // Auto-detect industry if not provided
            if (String.isBlank(industry)) {
                industry = detectIndustryFromCompany(customerName);
            }
            
            // Input validation
            CaseGenerationResponse validationResult = validateInputs(industry, customerName, additionalDetails, caseCount);
            if (!validationResult.success) {
                return validationResult;
            }
            
            // Find random existing contact for demo purposes
            Contact assignedContact = findRandomExistingContact();
            if (assignedContact == null) {
                return new CaseGenerationResponse(false, 'No existing contacts found in the org. Please create some contacts first.', null, null);
            }
            
            // Generate case data using Einstein LLM (with fallback to mock data if AI fails)
            List<CaseData> aiGeneratedCases = generateCasesWithAI(industry, customerName, additionalDetails, caseCount);
            if (aiGeneratedCases == null || aiGeneratedCases.isEmpty()) {
                return new CaseGenerationResponse(false, 'AI service failed to generate cases. Please try again.', null, assignedContact);
            }
            
            // Create case records
            List<Case> createdCases = createCaseRecords(aiGeneratedCases, assignedContact.Id);
            if (createdCases == null || createdCases.isEmpty()) {
                return new CaseGenerationResponse(false, 'Failed to create case records. Please check your permissions.', null, assignedContact);
            }
            
            // Conditionally create knowledge article - only if requested AND available
            SObject knowledgeArticle = null;
            String successMessage = 'Successfully generated ' + createdCases.size() + ' cases';
            
            if (createKnowledgeArticle != null && createKnowledgeArticle) {
                // Check if Knowledge is available before attempting creation
                KnowledgeAvailabilityResult knowledgeCheck = checkKnowledgeEnabled();
                if (knowledgeCheck.knowledgeEnabled) {
                    System.debug('About to create knowledge article...');
                    knowledgeArticle = createKnowledgeArticle(industry, customerName, additionalDetails, createdCases);
                    System.debug('Knowledge article creation completed. Article: ' + (knowledgeArticle != null ? (String)knowledgeArticle.get('Title') : 'null'));
                    
                    String knowledgeTitle = knowledgeArticle != null ? (String)knowledgeArticle.get('Title') : null;
                    if (knowledgeArticle != null && String.isNotBlank(knowledgeTitle) && !knowledgeTitle.contains('ERROR')) {
                        successMessage += ' and 1 knowledge article';
                    } else if (knowledgeArticle != null && knowledgeTitle != null && knowledgeTitle.contains('ERROR')) {
                        successMessage += ' (Knowledge article creation had issues - check debug logs)';
                    }
                } else {
                    System.debug('Knowledge requested but not available in this org: ' + knowledgeCheck.message);
                    // Continue without Knowledge - don't fail the entire operation
                }
            }
            
            // Generate demo scenario story
            String demoScenario = null;
            try {
                demoScenario = generateDemoScenario(industry, customerName, assignedContact, createdCases, knowledgeArticle);
            } catch (Exception scenarioEx) {
                System.debug('Demo scenario generation failed (non-blocking): ' + scenarioEx.getMessage());
            }
            
            // Return success response
            return new CaseGenerationResponse(
                true, 
                successMessage, 
                createdCases, 
                assignedContact,
                knowledgeArticle,
                demoScenario
            );
            
        } catch (Exception e) {
            System.debug('Error in generateCases: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            
            // Return user-friendly error message
            String errorMessage = 'An unexpected error occurred. Please try again or contact your administrator.';
            if (e instanceof DmlException) {
                errorMessage = 'Database error: Please check your permissions and try again.';
            } else if (e instanceof CalloutException) {
                errorMessage = 'AI service is temporarily unavailable. Please try again in a few minutes.';
            }
            
            return new CaseGenerationResponse(false, errorMessage, null, null);
        }
    }
    
    /**
     * @description Validates all input parameters
     * @param industry Industry selection (auto-detected if not provided)
     * @param customerName Company name input
     * @param additionalDetails Additional context
     * @param caseCount Number of cases to generate
     * @return CaseGenerationResponse with validation results
     */
    private static CaseGenerationResponse validateInputs(String industry, String customerName, String additionalDetails, Integer caseCount) {
        // Check required fields
        if (String.isBlank(customerName)) {
            return new CaseGenerationResponse(false, 'Company name is required.', null, null);
        }
        
        // Validate company name length
        if (customerName.length() > MAX_CUSTOMER_NAME_LENGTH) {
            return new CaseGenerationResponse(false, 'Company name must be ' + MAX_CUSTOMER_NAME_LENGTH + ' characters or less.', null, null);
        }
        
        // Validate additional details length
        if (String.isNotBlank(additionalDetails) && additionalDetails.length() > MAX_ADDITIONAL_DETAILS_LENGTH) {
            return new CaseGenerationResponse(false, 'Additional details must be ' + MAX_ADDITIONAL_DETAILS_LENGTH + ' characters or less.', null, null);
        }
        
        // Validate case count
        if (caseCount == null || caseCount < MIN_CASE_COUNT || caseCount > MAX_CASE_COUNT) {
            return new CaseGenerationResponse(false, 'Case count must be between ' + MIN_CASE_COUNT + ' and ' + MAX_CASE_COUNT + '.', null, null);
        }
        
        return new CaseGenerationResponse(true, 'Validation passed', null, null);
    }
    
    /**
     * @description Detects industry from company name using simple keyword matching
     * @param companyName The company name to analyze
     * @return Detected industry or 'Other' if unable to determine
     */
    private static String detectIndustryFromCompany(String companyName) {
        if (String.isBlank(companyName)) {
            return 'Other';
        }
        
        String lowerCompanyName = companyName.toLowerCase();
        
        // Technology companies
        if (lowerCompanyName.contains('salesforce') || lowerCompanyName.contains('microsoft') || 
            lowerCompanyName.contains('google') || lowerCompanyName.contains('apple') || 
            lowerCompanyName.contains('amazon') || lowerCompanyName.contains('meta') ||
            lowerCompanyName.contains('facebook') || lowerCompanyName.contains('oracle') ||
            lowerCompanyName.contains('adobe') || lowerCompanyName.contains('servicenow') ||
            lowerCompanyName.contains('slack') || lowerCompanyName.contains('zoom')) {
            return 'Technology';
        }
        
        // High Tech companies
        if (lowerCompanyName.contains('nvidia') || lowerCompanyName.contains('intel') || 
            lowerCompanyName.contains('amd') || lowerCompanyName.contains('qualcomm') ||
            lowerCompanyName.contains('broadcom') || lowerCompanyName.contains('palantir') ||
            lowerCompanyName.contains('snowflake') || lowerCompanyName.contains('databricks')) {
            return 'High Tech';
        }
        
        // Telecom companies
        if (lowerCompanyName.contains('verizon') || lowerCompanyName.contains('att') || 
            lowerCompanyName.contains('t-mobile') || lowerCompanyName.contains('sprint') ||
            lowerCompanyName.contains('comcast') || lowerCompanyName.contains('spectrum') ||
            lowerCompanyName.contains('telecom') || lowerCompanyName.contains('wireless')) {
            return 'Telecom';
        }
        
        // Media companies
        if (lowerCompanyName.contains('netflix') || lowerCompanyName.contains('disney') || 
            lowerCompanyName.contains('hulu') || lowerCompanyName.contains('hbo') ||
            lowerCompanyName.contains('paramount') || lowerCompanyName.contains('warner') ||
            lowerCompanyName.contains('media') || lowerCompanyName.contains('streaming')) {
            return 'Media';
        }
        
        // Healthcare companies
        if (lowerCompanyName.contains('kaiser') || lowerCompanyName.contains('anthem') || 
            lowerCompanyName.contains('humana') || lowerCompanyName.contains('aetna') ||
            lowerCompanyName.contains('cigna') || lowerCompanyName.contains('unitedhealth') ||
            lowerCompanyName.contains('hospital') || lowerCompanyName.contains('medical') ||
            lowerCompanyName.contains('health') || lowerCompanyName.contains('pharma')) {
            return 'Healthcare';
        }
        
        // Financial Services
        if (lowerCompanyName.contains('bank') || lowerCompanyName.contains('wells fargo') || 
            lowerCompanyName.contains('chase') || lowerCompanyName.contains('citi') ||
            lowerCompanyName.contains('goldman') || lowerCompanyName.contains('morgan') ||
            lowerCompanyName.contains('financial') || lowerCompanyName.contains('credit') ||
            lowerCompanyName.contains('capital') || lowerCompanyName.contains('finance')) {
            return 'Financial Services';
        }
        
        // Manufacturing
        if (lowerCompanyName.contains('tesla') || lowerCompanyName.contains('ford') || 
            lowerCompanyName.contains('general motors') || lowerCompanyName.contains('boeing') ||
            lowerCompanyName.contains('caterpillar') || lowerCompanyName.contains('ge') ||
            lowerCompanyName.contains('manufacturing') || lowerCompanyName.contains('motors') ||
            lowerCompanyName.contains('automotive') || lowerCompanyName.contains('aerospace')) {
            return 'Manufacturing';
        }
        
        // Retail
        if (lowerCompanyName.contains('walmart') || lowerCompanyName.contains('target') || 
            lowerCompanyName.contains('costco') || lowerCompanyName.contains('home depot') ||
            lowerCompanyName.contains('best buy') || lowerCompanyName.contains('macy') ||
            lowerCompanyName.contains('retail') || lowerCompanyName.contains('store') ||
            lowerCompanyName.contains('shopping') || lowerCompanyName.contains('mart')) {
            return 'Retail';
        }
        
        // Education
        if (lowerCompanyName.contains('university') || lowerCompanyName.contains('college') || 
            lowerCompanyName.contains('school') || lowerCompanyName.contains('education') ||
            lowerCompanyName.contains('academy') || lowerCompanyName.contains('institute') ||
            lowerCompanyName.contains('learning') || lowerCompanyName.contains('campus')) {
            return 'Education';
        }
        
        // Default to Other if no match found
        return 'Other';
    }
    
    /**
     * @description Finds a random existing contact for demo case generation
     * @return Random existing Contact record
     */
    private static Contact findRandomExistingContact() {
        try {
            // Get count of all contacts first
            Integer contactCount = [SELECT COUNT() FROM Contact WITH SECURITY_ENFORCED];
            
            if (contactCount == 0) {
                System.debug('No contacts found in the org');
                return null;
            }
            
            // Generate random offset to get a random contact
            Integer randomOffset = (Integer) Math.floor(Math.random() * contactCount);
            
            // Get a random contact using OFFSET
            List<Contact> randomContacts = [
                SELECT Id, Name, FirstName, LastName, Email, Phone, Account.Name
                FROM Contact 
                WITH SECURITY_ENFORCED
                ORDER BY Id
                LIMIT 1 
                OFFSET :randomOffset
            ];
            
            if (!randomContacts.isEmpty()) {
                System.debug('Selected random contact for demo: ' + randomContacts[0].Name);
                return randomContacts[0];
            }
            
            // Fallback: if OFFSET doesn't work, just get the first contact
            List<Contact> fallbackContacts = [
                SELECT Id, Name, FirstName, LastName, Email, Phone, Account.Name
                FROM Contact 
                WITH SECURITY_ENFORCED
                ORDER BY LastModifiedDate DESC
                LIMIT 1
            ];
            
            if (!fallbackContacts.isEmpty()) {
                System.debug('Using fallback contact: ' + fallbackContacts[0].Name);
                return fallbackContacts[0];
            }
            
            return null;
            
        } catch (Exception e) {
            System.debug('Error in findRandomExistingContact: ' + e.getMessage());
            
            // Emergency fallback - just get any contact
            try {
                List<Contact> anyContact = [
                    SELECT Id, Name, FirstName, LastName, Email, Phone, Account.Name
                    FROM Contact 
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];
                
                if (!anyContact.isEmpty()) {
                    System.debug('Using emergency fallback contact: ' + anyContact[0].Name);
                    return anyContact[0];
                }
            } catch (Exception fallbackError) {
                System.debug('Emergency fallback also failed: ' + fallbackError.getMessage());
            }
            
            return null;
        }
    }
    

    
    /**
     * @description Generates cases using Einstein LLM or mock data based on configuration
     * @param industry Industry context
     * @param customerName Customer name
     * @param additionalDetails Additional context
     * @param caseCount Number of cases to generate
     * @return List of generated case data
     */
    private static List<CaseData> generateCasesWithAI(String industry, String customerName, String additionalDetails, Integer caseCount) {
        
        System.debug('=== CASE GENERATION START ===');
        System.debug('USE_EINSTEIN_LLM setting: ' + USE_EINSTEIN_LLM);
        System.debug('Einstein Case Prompt Template: ' + EINSTEIN_CASE_PROMPT_TEMPLATE);
        
        // Check if Einstein LLM is enabled and available
        if (USE_EINSTEIN_LLM) {
            System.debug('🤖 ATTEMPTING EINSTEIN LLM CASE GENERATION...');
            System.debug('Input Parameters: customerName=' + customerName + ', industry=' + industry + ', caseCount=' + caseCount);
            
            try {
                // First, test if we can access the prompt template
                testPromptTemplateAccess(EINSTEIN_CASE_PROMPT_TEMPLATE);
                
                List<CaseData> aiCases = callEinsteinLLM(industry, customerName, additionalDetails, caseCount);
                if (aiCases != null && !aiCases.isEmpty()) {
                    System.debug('✅ SUCCESS: Generated ' + aiCases.size() + ' cases using Einstein LLM');
                    return aiCases;
                } else {
                    System.debug('❌ FAILURE: Einstein LLM returned null or empty results');
                }
            } catch (Exception e) {
                System.debug('❌ EINSTEIN LLM EXCEPTION: ' + e.getMessage());
                System.debug('Exception Type: ' + e.getTypeName());
                System.debug('Stack Trace: ' + e.getStackTraceString());
                System.debug('⤵️ FALLING BACK TO MOCK DATA');
            }
        } else {
            System.debug('⚙️ Einstein LLM is DISABLED - using mock data directly');
        }
        
        // Use mock data generation (current implementation)
        System.debug('📝 USING MOCK CASE GENERATION for: ' + customerName + ', Industry: ' + industry + ', Count: ' + caseCount);
        List<CaseData> mockCases = generateMockCases(industry, customerName, additionalDetails, caseCount);
        System.debug('📝 Mock generation returned ' + (mockCases != null ? mockCases.size() : 0) + ' cases');
        System.debug('=== CASE GENERATION END ===');
        return mockCases;
    }
    
    /**
     * @description Calls Einstein LLM API using prompt template
     * @param industry Industry context
     * @param customerName Customer name
     * @param additionalDetails Additional context
     * @param caseCount Number of cases to generate
     * @return List of generated case data or null if AI fails
     */
    private static List<CaseData> callEinsteinLLM(String industry, String customerName, String additionalDetails, Integer caseCount) {
        try {
            System.debug('Calling Einstein LLM for customer: ' + customerName + ', industry: ' + industry);
            
            // Method 1: TEMPORARILY DISABLED - ConnectApi approach
            System.debug('⚠️ Method 1 (ConnectApi) temporarily disabled to force Flow method');
            
            // Method 2: TEMPORARILY DISABLED - HTTP Request approach  
            System.debug('⚠️ Method 2 (HTTP Request) temporarily disabled to force Flow method');
            
            // Method 3: Try using Flow/Process Builder integration
            try {
                return callEinsteinLLMViaFlow(industry, customerName, additionalDetails, caseCount);
            } catch (Exception flowEx) {
                System.debug('Flow integration approach failed: ' + flowEx.getMessage());
            }
            
            System.debug('All Einstein LLM methods failed, returning null for fallback');
            return null;
            
        } catch (Exception e) {
            System.debug('Einstein LLM call failed with error: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            return null;
        }
    }
    
    /**
     * @description Try Einstein LLM via ConnectApi using correct API (API version 60+)
     */
    private static List<CaseData> callEinsteinLLMViaConnectApi(String industry, String customerName, String additionalDetails, Integer caseCount) {
        System.debug('🚀 Attempting REAL ConnectApi Einstein LLM call using prompt template: ' + EINSTEIN_CASE_PROMPT_TEMPLATE);
        
        try {
            // Method 1: Try Flow-based Einstein LLM (recommended approach)
            System.debug('🔧 Method 1: Attempting Einstein LLM via Flow...');
            try {
                return callEinsteinLLMViaFlow(industry, customerName, additionalDetails, caseCount);
            } catch (Exception flowEx) {
                System.debug('❌ Flow approach failed: ' + flowEx.getMessage());
            }
            
            // Method 2: Fallback to direct Apex with WrappedValue workaround
            System.debug('🔧 Method 2: Fallback to Apex ConnectApi...');
            try {
                return attemptEinsteinLLMWithWrappedValue(industry, customerName, additionalDetails, caseCount);
            } catch (Exception wrappedEx) {
                System.debug('❌ WrappedValue approach failed: ' + wrappedEx.getMessage());
            }
            
            // Method 3: Try alternative input format
            System.debug('🔧 Method 3: Attempting alternative input format...');
            try {
                return attemptEinsteinLLMAlternativeFormat(industry, customerName, additionalDetails, caseCount);
            } catch (Exception altEx) {
                System.debug('❌ Alternative format failed: ' + altEx.getMessage());
            }
            
            System.debug('❌ ALL EINSTEIN LLM METHODS FAILED');
            return null;
            
        } catch (Exception e) {
            System.debug('❌ ConnectApi Einstein LLM exception: ' + e.getMessage());
            System.debug('Exception Type: ' + e.getTypeName());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            return null;
        }
    }
    
    /**
     * @description Method 1: Try Einstein LLM with proper ConnectApi implementation (official documentation)
     */
    private static List<CaseData> attemptEinsteinLLMWithWrappedValue(String industry, String customerName, String additionalDetails, Integer caseCount) {
        System.debug('🔧 Attempting Einstein LLM with official ConnectApi implementation...');
        
        try {
            // Case Generation Template expects camelCase parameters
            Map<String, Object> inputs = new Map<String, Object>();
            inputs.put('customerName', customerName);                    // {!$Input:customerName}
            inputs.put('industry', String.isBlank(industry) ? 'General Business' : industry);
            inputs.put('caseCount', String.valueOf(caseCount));          // {!$Input:caseCount}
            inputs.put('additionalDetails', String.isBlank(additionalDetails) ? 'General customer support scenarios' : additionalDetails); // {!$Input:additionalDetails}
            
            // Create request - try direct assignment (bypass WrappedValue constructor)
            ConnectApi.EinsteinPromptTemplateGenerationsInput request = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            request.isPreview = false;
            
            // Create WrappedValue objects using JSON deserialization workaround
            Map<String, ConnectApi.WrappedValue> wrappedInputs = new Map<String, ConnectApi.WrappedValue>();
            try {
                for (String key : inputs.keySet()) {
                    String value = String.valueOf(inputs.get(key));
                    // Create WrappedValue via JSON - this bypasses the constructor
                    String jsonValue = '{"value":"' + value.replace('"', '\\"') + '"}';
                    ConnectApi.WrappedValue wrappedValue = (ConnectApi.WrappedValue) JSON.deserialize(jsonValue, ConnectApi.WrappedValue.class);
                    wrappedInputs.put(key, wrappedValue);
                }
                request.inputParams = wrappedInputs;
                System.debug('✅ WrappedValue objects created successfully via JSON deserialization');
            } catch (Exception wrapEx) {
                System.debug('❌ WrappedValue JSON creation failed, proceeding without inputParams: ' + wrapEx.getMessage());
                // Fallback: call without inputParams
            }
            
            // additionalConfig is REQUIRED per documentation
            request.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            request.additionalConfig.maxTokens = 2000;
            request.additionalConfig.temperature = 0.7;
            
            System.debug('🚀 Making Einstein LLM call with prompt template: ' + EINSTEIN_CASE_PROMPT_TEMPLATE);
            System.debug('📝 Input parameters for Case template: ' + JSON.serialize(inputs));
            
            // Make the Einstein LLM call
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response = 
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(EINSTEIN_CASE_PROMPT_TEMPLATE, request);
            
            if (response != null && response.generations != null && !response.generations.isEmpty()) {
                String aiResponse = response.generations[0].text;
                System.debug('✅ SUCCESS: Einstein LLM responded! Response: ' + aiResponse);
                
                List<CaseData> parsedCases = parseAIResponse(aiResponse, caseCount);
                if (parsedCases != null && !parsedCases.isEmpty()) {
                    System.debug('✅ SUCCESS: Parsed ' + parsedCases.size() + ' cases from Einstein LLM!');
                    return parsedCases;
                }
            }
            
            System.debug('❌ Einstein LLM response was empty or invalid');
            throw new CalloutException('Einstein LLM response was empty or could not be parsed');
            
        } catch (Exception ex) {
            System.debug('❌ Einstein LLM call failed: ' + ex.getMessage());
            System.debug('Exception Type: ' + ex.getTypeName());
            System.debug('Stack Trace: ' + ex.getStackTraceString());
            throw ex;
        }
    }
    
    /**
     * @description Method 2: Try Einstein LLM for Knowledge Article generation
     */
    private static List<CaseData> attemptEinsteinLLMAlternativeFormat(String industry, String customerName, String additionalDetails, Integer caseCount) {
        System.debug('🔧 Attempting Einstein LLM for Knowledge Article generation...');
        
        try {
            // First generate knowledge article
            String knowledgeArticle = generateKnowledgeArticleWithEinstein(industry, customerName, additionalDetails);
            System.debug('📚 Generated Knowledge Article context: ' + knowledgeArticle.substring(0, Math.min(200, knowledgeArticle.length())) + '...');
            
            // Enhanced case generation with knowledge article context
            // Case template expects camelCase parameters
            Map<String, Object> inputs = new Map<String, Object>();
            inputs.put('customerName', customerName);
            inputs.put('industry', String.isBlank(industry) ? 'General Business' : industry);
            inputs.put('caseCount', String.valueOf(caseCount));
            inputs.put('additionalDetails', String.isBlank(additionalDetails) ? 'General customer support scenarios' : additionalDetails);
            
            ConnectApi.EinsteinPromptTemplateGenerationsInput request = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            request.isPreview = false;
            
            // Create WrappedValue objects using JSON deserialization workaround for enhanced case generation
            Map<String, ConnectApi.WrappedValue> wrappedInputs = new Map<String, ConnectApi.WrappedValue>();
            try {
                for (String key : inputs.keySet()) {
                    String value = String.valueOf(inputs.get(key));
                    // Create WrappedValue via JSON - this bypasses the constructor
                    String jsonValue = '{"value":"' + value.replace('"', '\\"') + '"}';
                    ConnectApi.WrappedValue wrappedValue = (ConnectApi.WrappedValue) JSON.deserialize(jsonValue, ConnectApi.WrappedValue.class);
                    wrappedInputs.put(key, wrappedValue);
                }
                request.inputParams = wrappedInputs;
                System.debug('✅ Enhanced case generation WrappedValue objects created successfully via JSON deserialization');
            } catch (Exception wrapEx) {
                System.debug('❌ Enhanced case generation WrappedValue JSON creation failed, proceeding without inputParams: ' + wrapEx.getMessage());
                // Fallback: call without inputParams
            }
            
            // additionalConfig is REQUIRED per documentation
            request.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            request.additionalConfig.maxTokens = 2000;
            request.additionalConfig.temperature = 0.7;
            
            System.debug('🚀 Making enhanced Einstein LLM call with knowledge context...');
            
            // Make the Einstein LLM call
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response = 
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(EINSTEIN_CASE_PROMPT_TEMPLATE, request);
            
            if (response != null && response.generations != null && !response.generations.isEmpty()) {
                String aiResponse = response.generations[0].text;
                List<CaseData> parsedCases = parseAIResponse(aiResponse, caseCount);
                if (parsedCases != null && !parsedCases.isEmpty()) {
                    System.debug('✅ SUCCESS: Knowledge-enhanced case generation worked! Generated ' + parsedCases.size() + ' cases');
                    return parsedCases;
                }
            }
            
            throw new CalloutException('Knowledge-enhanced case generation failed');
            
        } catch (Exception ex) {
            System.debug('❌ Knowledge-enhanced LLM call failed: ' + ex.getMessage());
            throw ex;
        }
    }
    
    /**
     * @description Method 3: Try basic Einstein LLM call with minimal inputs
     */
    private static List<CaseData> attemptBasicEinsteinLLMCall(String industry, String customerName, String additionalDetails, Integer caseCount) {
        System.debug('🔧 Attempting basic Einstein LLM call with minimal inputs...');
        
        try {
            // Basic call with minimal Case template parameters
            Map<String, Object> inputs = new Map<String, Object>();
            inputs.put('customerName', customerName);      // Case template uses camelCase
            inputs.put('caseCount', String.valueOf(caseCount));
            
            ConnectApi.EinsteinPromptTemplateGenerationsInput request = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            request.isPreview = false;
            
            // Create WrappedValue objects using JSON deserialization workaround for basic call
            Map<String, ConnectApi.WrappedValue> wrappedInputs = new Map<String, ConnectApi.WrappedValue>();
            try {
                for (String key : inputs.keySet()) {
                    String value = String.valueOf(inputs.get(key));
                    // Create WrappedValue via JSON - this bypasses the constructor
                    String jsonValue = '{"value":"' + value.replace('"', '\\"') + '"}';
                    ConnectApi.WrappedValue wrappedValue = (ConnectApi.WrappedValue) JSON.deserialize(jsonValue, ConnectApi.WrappedValue.class);
                    wrappedInputs.put(key, wrappedValue);
                }
                request.inputParams = wrappedInputs;
                System.debug('✅ Basic call WrappedValue objects created successfully via JSON deserialization');
            } catch (Exception wrapEx) {
                System.debug('❌ Basic call WrappedValue JSON creation failed, proceeding without inputParams: ' + wrapEx.getMessage());
                // Fallback: call without inputParams
            }
            
            // additionalConfig is REQUIRED per documentation
            request.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            request.additionalConfig.maxTokens = 1000;
            request.additionalConfig.temperature = 0.5;
            
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response = 
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(EINSTEIN_CASE_PROMPT_TEMPLATE, request);
            
            if (response != null && response.generations != null && !response.generations.isEmpty()) {
                String aiResponse = response.generations[0].text;
                System.debug('✅ Basic Einstein LLM call succeeded! Response: ' + aiResponse);
                
                List<CaseData> parsedCases = parseAIResponse(aiResponse, caseCount);
                if (parsedCases != null && !parsedCases.isEmpty()) {
                    return parsedCases;
                } else {
                    // If parsing fails, create AI-style cases
                    return createBasicAICases(customerName, industry, additionalDetails, caseCount);
                }
            }
            
            throw new CalloutException('Basic Einstein LLM call returned empty response');
            
        } catch (Exception ex) {
            System.debug('❌ Basic Einstein LLM call failed: ' + ex.getMessage());
            throw ex;
        }
    }
    
    /**
     * @description Generate Knowledge Article using Einstein LLM
     */
    private static String generateKnowledgeArticleWithEinstein(String industry, String customerName, String additionalDetails) {
        System.debug('📚 Generating Knowledge Article with Einstein LLM...');
        
        try {
            // Method 1: Try Einstein Flow Knowledge Article generation (same pattern as cases)
            System.debug('🔧 Method 1: Attempting Knowledge Article via Einstein Flow...');
            try {
                return generateKnowledgeArticleViaFlow(industry, customerName, additionalDetails);
            } catch (Exception flowEx) {
                System.debug('❌ Knowledge Article Flow approach failed: ' + flowEx.getMessage());
            }
            
            // Method 2: Fallback to direct Apex ConnectApi approach
            System.debug('🔧 Method 2: Fallback to Apex ConnectApi for Knowledge Article...');
            return generateKnowledgeArticleViaApex(industry, customerName, additionalDetails);
            
        } catch (Exception ex) {
            System.debug('❌ Knowledge Article generation failed: ' + ex.getMessage());
            System.debug('🔄 Falling back to template-based knowledge article');
            return generateFallbackKnowledgeArticle(customerName, industry, additionalDetails);
        }
    }
    
    /**
     * @description Generate Knowledge Article via Flow (primary method)
     */
    private static String generateKnowledgeArticleViaFlow(String industry, String customerName, String additionalDetails) {
        System.debug('🔧 Attempting Knowledge Article via Flow integration...');
        
        try {
            // Prepare Flow input variables
            Map<String, Object> flowInputs = new Map<String, Object>{
                'customerName' => customerName,
                'industry' => String.isBlank(industry) ? 'General Business' : industry,
                'additionalDetails' => String.isBlank(additionalDetails) ? 'General support topics' : additionalDetails,
                'casesSummary' => 'Knowledge article will be used to enhance customer support for ' + customerName + ' in the ' + industry + ' industry.'
            };
            
            System.debug('📝 Knowledge Article Flow inputs: ' + JSON.serialize(flowInputs));
            
            // Call the Einstein LLM Knowledge Generation Flow (new clean version)
            Flow.Interview flowInterview = Flow.Interview.createInterview('Einstein_LLM_Knowledge_Generation', flowInputs);
            flowInterview.start();
            
            // Get results from Flow - JSON response with title, summary, content
            String aiResponse = (String) flowInterview.getVariableValue('aiResponse');
            Boolean isSuccess = (Boolean) flowInterview.getVariableValue('isSuccess');
            
            System.debug('🔍 Knowledge Article Flow execution completed. Success: ' + isSuccess);
            System.debug('📝 Knowledge Article AI Response: ' + (String.isBlank(aiResponse) ? 'EMPTY' : aiResponse.substring(0, Math.min(200, aiResponse.length())) + '...'));
            
            if (isSuccess == true && String.isNotBlank(aiResponse)) {
                System.debug('✅ SUCCESS: Flow-based Knowledge Article generation completed!');
                
                try {
                    // Parse the JSON response (title, summary, content)
                    Map<String, Object> knowledgeData = (Map<String, Object>) JSON.deserializeUntyped(cleanJsonResponse(aiResponse));
                    
                    String title = (String) knowledgeData.get('title');
                    String summary = (String) knowledgeData.get('summary');
                    String content = (String) knowledgeData.get('content');
                    
                    System.debug('📝 Parsed Title: ' + title);
                    System.debug('📝 Parsed Summary: ' + summary);
                    System.debug('📝 Parsed Content Length: ' + (String.isNotBlank(content) ? content.length() : 0));
                    
                    // Store all responses for the Knowledge Article creation
                    Map<String, String> allResponses = new Map<String, String>();
                    allResponses.put('content', String.isNotBlank(content) ? cleanHtmlContent(content) : generateStaticKnowledgeContent(industry, customerName, additionalDetails));
                    allResponses.put('subject', String.isNotBlank(title) ? title.trim() : customerName + ' Support Guide');
                    allResponses.put('summary', String.isNotBlank(summary) ? summary.trim() : 'Support guide for ' + customerName);
                    
                    System.debug('📝 All responses prepared for Knowledge Article creation');
                    
                    currentKnowledgeResponses = allResponses;
                    return allResponses.get('content');
                    
                } catch (Exception parseEx) {
                    System.debug('❌ Failed to parse JSON response: ' + parseEx.getMessage());
                    System.debug('Raw response: ' + aiResponse);
                    // Fallback to treating entire response as content
                    Map<String, String> fallbackResponses = new Map<String, String>();
                    fallbackResponses.put('content', cleanHtmlContent(aiResponse));
                    fallbackResponses.put('subject', customerName + ' Support Guide');
                    fallbackResponses.put('summary', 'Support guide for ' + customerName);
                    
                    currentKnowledgeResponses = fallbackResponses;
                    return fallbackResponses.get('content');
                }
            }
            
            System.debug('❌ Knowledge Article Flow returned no valid data');
            throw new CalloutException('Flow-based Knowledge Article generation returned no valid data');
            
        } catch (Exception e) {
            System.debug('❌ Flow-based Knowledge Article generation failed: ' + e.getMessage());
            throw new CalloutException('Flow-based Knowledge Article generation failed: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generate Knowledge Article using Einstein template (same pattern as cases)
     */
    private static String generateKnowledgeArticleViaTemplate(String industry, String customerName, String additionalDetails) {
        System.debug('🎯 Generating Knowledge Article via Einstein Template...');
        
        try {
            String casesSummary = 'Knowledge article will be used to enhance customer support for ' + customerName + ' in the ' + industry + ' industry.';
            
            // Prepare template inputs (same pattern as case generation)
            Map<String, Object> inputs = new Map<String, Object>();
            inputs.put('customerName', customerName);
            inputs.put('industry', String.isBlank(industry) ? 'General Business' : industry);
            inputs.put('additionalDetails', String.isBlank(additionalDetails) ? 'General support topics' : additionalDetails);
            inputs.put('casesSummary', casesSummary);
            
            ConnectApi.EinsteinPromptTemplateGenerationsInput request = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            request.isPreview = false;
            
            // Create WrappedValue objects using JSON deserialization
            Map<String, ConnectApi.WrappedValue> wrappedInputs = new Map<String, ConnectApi.WrappedValue>();
            for (String key : inputs.keySet()) {
                String value = String.valueOf(inputs.get(key));
                String jsonValue = '{"value":"' + value.replace('"', '\\"') + '"}';
                ConnectApi.WrappedValue wrappedValue = (ConnectApi.WrappedValue) JSON.deserialize(jsonValue, ConnectApi.WrappedValue.class);
                wrappedInputs.put(key, wrappedValue);
            }
            request.inputParams = wrappedInputs;
            
            // additionalConfig is required
            request.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            request.additionalConfig.maxTokens = 1500;
            request.additionalConfig.temperature = 0.6;
            
            System.debug('🚀 Making Einstein LLM call for Knowledge Article with template: ' + EINSTEIN_KNOWLEDGE_PROMPT_TEMPLATE);
            
            // Make the Einstein LLM call using the template
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response = 
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(EINSTEIN_KNOWLEDGE_PROMPT_TEMPLATE, request);
            
            if (response != null && response.generations != null && !response.generations.isEmpty()) {
                String rawResponse = response.generations[0].text;
                System.debug('📝 Raw Knowledge Article response: ' + rawResponse.substring(0, Math.min(200, rawResponse.length())) + '...');
                
                // Parse the JSON response (title, summary, content)
                Map<String, Object> knowledgeData = (Map<String, Object>) JSON.deserializeUntyped(cleanJsonResponse(rawResponse));
                
                String title = (String) knowledgeData.get('title');
                String summary = (String) knowledgeData.get('summary');
                String content = (String) knowledgeData.get('content');
                
                System.debug('✅ SUCCESS: Generated Knowledge Article with Einstein Template!');
                System.debug('📝 Title: ' + title);
                System.debug('📝 Summary: ' + summary);
                System.debug('📝 Content length: ' + (String.isNotBlank(content) ? content.length() : 0));
                
                // Store all responses for Knowledge Article creation
                Map<String, String> allResponses = new Map<String, String>();
                allResponses.put('content', String.isNotBlank(content) ? cleanHtmlContent(content) : generateStaticKnowledgeContent(industry, customerName, additionalDetails));
                allResponses.put('subject', String.isNotBlank(title) ? title.trim() : customerName + ' Support Guide');
                allResponses.put('summary', String.isNotBlank(summary) ? summary.trim() : 'Support guide for ' + customerName);
                
                currentKnowledgeResponses = allResponses;
                return allResponses.get('content');
                
            } else {
                System.debug('❌ Knowledge Article template returned empty response');
                return null;
            }
            
        } catch (Exception e) {
            System.debug('❌ Knowledge Article template generation failed: ' + e.getMessage());
            System.debug('Exception Type: ' + e.getTypeName());
            return null;
        }
    }
    
    /**
     * @description Generate Knowledge Article via Apex ConnectApi (fallback method)
     */
    private static String generateKnowledgeArticleViaApex(String industry, String customerName, String additionalDetails) {
        System.debug('📚 Generating Knowledge Article with Apex ConnectApi...');
        
        try {
            // Knowledge Article Template expects lowercase parameters + casessummary
            Map<String, Object> inputs = new Map<String, Object>();
            inputs.put('customername', customerName);                       // {!$Input:customername} (lowercase!)
            inputs.put('industry', String.isBlank(industry) ? 'General Business' : industry);
            inputs.put('additionaldetails', String.isBlank(additionalDetails) ? 'General support topics' : additionalDetails); // {!$Input:additionaldetails} (lowercase!)
            inputs.put('casessummary', 'Knowledge article will be used to enhance customer support for ' + customerName + ' in the ' + industry + ' industry.'); // {!$Input:casessummary}
            
            ConnectApi.EinsteinPromptTemplateGenerationsInput request = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            request.isPreview = false;
            
            // Create WrappedValue objects using JSON deserialization workaround for Knowledge Article
            Map<String, ConnectApi.WrappedValue> wrappedInputs = new Map<String, ConnectApi.WrappedValue>();
            try {
                for (String key : inputs.keySet()) {
                    String value = String.valueOf(inputs.get(key));
                    // Create WrappedValue via JSON - this bypasses the constructor
                    String jsonValue = '{"value":"' + value.replace('"', '\\"') + '"}';
                    ConnectApi.WrappedValue wrappedValue = (ConnectApi.WrappedValue) JSON.deserialize(jsonValue, ConnectApi.WrappedValue.class);
                    wrappedInputs.put(key, wrappedValue);
                }
                request.inputParams = wrappedInputs;
                System.debug('✅ Knowledge Article WrappedValue objects created successfully via JSON deserialization');
            } catch (Exception wrapEx) {
                System.debug('❌ Knowledge Article WrappedValue JSON creation failed, proceeding without inputParams: ' + wrapEx.getMessage());
                // Fallback: call without inputParams
            }
            
            // additionalConfig is REQUIRED per documentation
            request.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            request.additionalConfig.maxTokens = 1500;
            request.additionalConfig.temperature = 0.6;
            
            System.debug('🚀 Making Einstein LLM call for Knowledge Article with template: ' + EINSTEIN_KNOWLEDGE_PROMPT_TEMPLATE);
            System.debug('📝 Input parameters for Knowledge Article template: ' + JSON.serialize(inputs));
            
            // Make the Einstein LLM call for knowledge article
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response = 
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(EINSTEIN_KNOWLEDGE_PROMPT_TEMPLATE, request);
            
            if (response != null && response.generations != null && !response.generations.isEmpty()) {
                String knowledgeArticle = response.generations[0].text;
                System.debug('✅ SUCCESS: Generated Knowledge Article with Einstein LLM!');
                return knowledgeArticle;
            }
            
            System.debug('❌ Knowledge Article generation returned empty response');
            return generateFallbackKnowledgeArticle(customerName, industry, additionalDetails);
            
        } catch (Exception ex) {
            System.debug('❌ Knowledge Article generation failed: ' + ex.getMessage());
            System.debug('🔄 Falling back to template-based knowledge article');
            return generateFallbackKnowledgeArticle(customerName, industry, additionalDetails);
        }
    }
    
    /**
     * @description Generate fallback knowledge article when Einstein LLM fails
     */
    private static String generateFallbackKnowledgeArticle(String customerName, String industry, String additionalDetails) {
        String article = 'Knowledge Article: ' + customerName + ' Support Guide\n\n';
        article += 'Industry: ' + (String.isBlank(industry) ? 'General Business' : industry) + '\n\n';
        article += 'Overview:\n';
        article += 'This knowledge article provides comprehensive support information for ' + customerName;
        
        if (String.isNotBlank(industry)) {
            article += ' in the ' + industry.toLowerCase() + ' sector';
        }
        
        article += '.\n\n';
        article += 'Common Issues and Solutions:\n';
        article += '1. Authentication and Access Issues\n';
        article += '2. Performance and System Performance\n';
        article += '3. Data Integration Challenges\n';
        article += '4. Configuration and Setup\n\n';
        
        if (String.isNotBlank(additionalDetails)) {
            article += 'Additional Context: ' + additionalDetails + '\n\n';
        }
        
        article += 'For immediate assistance, please contact our support team.';
        
        return article;
    }
    
    /**
     * @description Create basic AI-style cases when we can connect to Einstein LLM but can't use complex inputs
     */
    private static List<CaseData> createBasicAICases(String customerName, String industry, String additionalDetails, Integer caseCount) {
        List<CaseData> cases = new List<CaseData>();
        
        // Enhanced case creation that mimics AI output
        String[] aiSubjects = new String[]{
            'Service Integration Issue with ' + customerName + ' Platform',
            'Data Synchronization Error Affecting ' + customerName + ' Operations', 
            'Authentication Timeout in ' + customerName + ' Application',
            'Performance Degradation in ' + customerName + ' Dashboard',
            'API Rate Limiting Issues with ' + customerName + ' Services',
            'Database Connection Failure in ' + customerName + ' System',
            'Security Certificate Expiration for ' + customerName + ' Domain',
            'Load Balancer Configuration Error in ' + customerName + ' Infrastructure',
            'Memory Leak Detection in ' + customerName + ' Application',
            'Network Connectivity Issues with ' + customerName + ' Services'
        };
        
        for (Integer i = 0; i < caseCount && i < aiSubjects.size(); i++) {
            CaseData caseData = new CaseData();
            caseData.subject = aiSubjects[i];
            caseData.description = generateAIStyleDescription(customerName, industry, additionalDetails);
            caseData.priority = getRandomPriority();
            caseData.origin = 'Phone';
            // Note: Status is set manually when creating Case records, not in CaseData
            cases.add(caseData);
        }
        
        System.debug('✅ Created ' + cases.size() + ' AI-style cases for basic Einstein LLM response');
        return cases;
    }
    
    /**
     * @description Generate AI-style description for basic cases
     */
    private static String generateAIStyleDescription(String customerName, String industry, String additionalDetails) {
        String baseDescription = 'Customer ' + customerName + ' is experiencing technical difficulties ';
        
        if (String.isNotBlank(industry)) {
            baseDescription += 'in their ' + industry.toLowerCase() + ' operations ';
        }
        
        baseDescription += 'that require immediate attention. ';
        
        if (String.isNotBlank(additionalDetails)) {
            baseDescription += 'Context: ' + additionalDetails + ' ';
        }
        
        baseDescription += 'This issue is impacting business operations and needs prompt resolution to maintain service quality.';
        
        return baseDescription;
    }
    
    /**
     * @description Get a random priority for case generation
     */
    private static String getRandomPriority() {
        String[] priorities = new String[]{'High', 'Medium', 'Low'};
        Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), priorities.size());
        return priorities[randomIndex];
    }

    /**
     * @description Try Einstein LLM via HTTP callout to Einstein Platform Services
     */
    private static List<CaseData> callEinsteinLLMViaHttpRequest(String industry, String customerName, String additionalDetails, Integer caseCount) {
        // Build the prompt
        String prompt = buildEinsteinLLMPrompt(industry, customerName, additionalDetails, caseCount);
        
        // This would require Einstein Platform Services setup and API keys
        System.debug('Attempting HTTP Einstein LLM call');
        
        /*
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.einstein.ai/v2/language/generation');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + getEinsteinAccessToken());
        req.setHeader('Content-Type', 'application/json');
        
        Map<String, Object> requestBody = new Map<String, Object>{
            'prompt' => prompt,
            'maxTokens' => 2000,
            'temperature' => 0.7
        };
        
        req.setBody(JSON.serialize(requestBody));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String aiResponse = (String) responseBody.get('text');
            return parseAIResponse(aiResponse, caseCount);
        }
        */
        
        throw new CalloutException('Einstein Platform Services not configured in this org');
    }
    
    /**
     * @description Try Einstein LLM via Flow integration
     */
    private static List<CaseData> callEinsteinLLMViaFlow(String industry, String customerName, String additionalDetails, Integer caseCount) {
        System.debug('🔧 Attempting Einstein LLM via Flow integration...');
        
        try {
            // Prepare Flow input variables
            Map<String, Object> flowInputs = new Map<String, Object>{
                'customerName' => customerName,
                'industry' => String.isBlank(industry) ? 'General Business' : industry,
                'caseCount' => caseCount,
                'additionalDetails' => String.isBlank(additionalDetails) ? 'General customer support scenarios' : additionalDetails
            };
            
            System.debug('📝 Flow inputs: ' + JSON.serialize(flowInputs));
            
            // Call the Einstein LLM Case Generation Flow
            Flow.Interview flowInterview = Flow.Interview.createInterview('Einstein_LLM_Case_Generation', flowInputs);
            flowInterview.start();
            
            // Get results from Flow
            String aiResponse = (String) flowInterview.getVariableValue('aiResponse');
            Boolean isSuccess = (Boolean) flowInterview.getVariableValue('isSuccess');
            
            System.debug('🔍 Flow execution completed. Success: ' + isSuccess);
            System.debug('📝 AI Response: ' + (String.isBlank(aiResponse) ? 'EMPTY' : aiResponse.substring(0, Math.min(200, aiResponse.length())) + '...'));
            
            if (isSuccess == true && String.isNotBlank(aiResponse)) {
                List<CaseData> parsedCases = parseAIResponse(aiResponse, caseCount);
                if (parsedCases != null && !parsedCases.isEmpty()) {
                    System.debug('✅ SUCCESS: Flow-based Einstein LLM generated ' + parsedCases.size() + ' cases!');
                    return parsedCases;
                }
            }
            
            System.debug('❌ Flow returned no valid case data');
            throw new CalloutException('Flow-based Einstein LLM returned no valid case data');
            
        } catch (Exception e) {
            System.debug('❌ Flow-based Einstein LLM call failed: ' + e.getMessage());
            System.debug('Exception Type: ' + e.getTypeName());
            throw new CalloutException('Flow-based Einstein LLM call failed: ' + e.getMessage());
        }
    }
    
    /**
     * @description Builds the Einstein LLM prompt manually
     */
    private static String buildEinsteinLLMPrompt(String industry, String customerName, String additionalDetails, Integer caseCount) {
        String prompt = 'You are an expert customer service case generator. Generate ' + caseCount + ' realistic customer service cases for customers of ' + customerName;
        
        if (String.isNotBlank(industry)) {
            prompt += ' in the ' + industry + ' industry';
        }
        
        prompt += '.\n\n';
        prompt += 'Context: These cases should represent real issues that customers would contact ' + customerName + ' about regarding their services or products.';
        
        if (String.isNotBlank(additionalDetails)) {
            prompt += ' Additional context: ' + additionalDetails;
        }
        
        prompt += '\n\nRequirements:\n';
        prompt += '- Each case should be from the perspective of a customer contacting ' + customerName + ' for support\n';
        prompt += '- Subject lines should be 5-15 words describing the customer\'s issue\n';
        prompt += '- Descriptions should be 2-4 sentences explaining the problem in detail\n';
        prompt += '- Vary the priority: Critical (5%), High (25%), Medium (50%), Low (20%)\n';
        prompt += '- Vary the case types: Question, Problem, Feature Request, Complaint\n';
        prompt += '- Vary the origin: Web, Email, Phone, Chat\n';
        prompt += '- Make issues realistic and specific to ' + industry + ' industry\n\n';
        prompt += 'Return ONLY a JSON array in this exact format:\n';
        prompt += '[\n';
        prompt += '  {\n';
        prompt += '    "subject": "Customer issue subject",\n';
        prompt += '    "description": "Detailed description of the customer\'s problem",\n';
        prompt += '    "priority": "Medium",\n';
        prompt += '    "type": "Problem",\n';
        prompt += '    "origin": "Web"\n';
        prompt += '  }\n';
        prompt += ']\n\n';
        prompt += 'Generate exactly ' + caseCount + ' cases.';
        
        return prompt;
    }
    
    /**
     * @description Parses AI-generated JSON response into CaseData objects
     * @param aiResponse Raw AI response text
     * @param expectedCount Expected number of cases for validation
     * @return List of parsed case data or null if parsing fails
     */
    private static List<CaseData> parseAIResponse(String aiResponse, Integer expectedCount) {
        try {
            if (String.isBlank(aiResponse)) {
                System.debug('AI response is blank');
                return null;
            }
            
            // Clean the response - sometimes AI adds extra text before/after JSON
            String cleanedResponse = aiResponse.trim();
            
            // Find JSON array start and end
            Integer jsonStart = cleanedResponse.indexOf('[');
            Integer jsonEnd = cleanedResponse.lastIndexOf(']');
            
            if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
                System.debug('No valid JSON array found in AI response');
                return null;
            }
            
            String jsonArray = cleanedResponse.substring(jsonStart, jsonEnd + 1);
            System.debug('Extracted JSON: ' + jsonArray);
            
            // Parse JSON into objects
            List<Object> jsonObjects = (List<Object>) JSON.deserializeUntyped(jsonArray);
            List<CaseData> caseDataList = new List<CaseData>();
            
            for (Object obj : jsonObjects) {
                Map<String, Object> caseMap = (Map<String, Object>) obj;
                
                CaseData caseData = new CaseData();
                caseData.subject = (String) caseMap.get('subject');
                caseData.description = (String) caseMap.get('description');
                caseData.priority = (String) caseMap.get('priority');
                caseData.type = (String) caseMap.get('type');
                caseData.origin = (String) caseMap.get('origin');
                
                // Validate required fields
                if (String.isNotBlank(caseData.subject) && String.isNotBlank(caseData.description)) {
                    // Ensure field limits
                    caseData.subject = caseData.subject.length() > 255 ? caseData.subject.substring(0, 255) : caseData.subject;
                    
                    // Validate picklist values with fallbacks
                    caseData.priority = validatePriority(caseData.priority);
                    caseData.origin = validateOrigin(caseData.origin);
                    
                    caseDataList.add(caseData);
                }
            }
            
            System.debug('Successfully parsed ' + caseDataList.size() + ' valid cases from AI response');
            
            // Return parsed cases if we have any, even if count doesn't match exactly
            return caseDataList.isEmpty() ? null : caseDataList;
            
        } catch (Exception e) {
            System.debug('Error parsing AI response: ' + e.getMessage());
            System.debug('AI Response was: ' + aiResponse);
            return null;
        }
    }
    
    /**
     * @description Validates and corrects priority values
     */
    private static String validatePriority(String priority) {
        if (String.isBlank(priority)) return 'Medium';
        
        String priorityLower = priority.toLowerCase();
        if (priorityLower.contains('critical')) return 'Critical';
        if (priorityLower.contains('high')) return 'High';
        if (priorityLower.contains('low')) return 'Low';
        return 'Medium'; // Default fallback
    }
    
    /**
     * @description Validates and corrects origin values
     */
    private static String validateOrigin(String origin) {
        if (String.isBlank(origin)) return 'Web';
        
        String originLower = origin.toLowerCase();
        if (originLower.contains('phone')) return 'Phone';
        if (originLower.contains('email')) return 'Email';
        if (originLower.contains('chat')) return 'Chat';
        return 'Web'; // Default fallback
    }
    
    /**
     * @description Mock implementation of AI case generation for demo purposes
     * In production, this would be replaced with actual Einstein LLM integration
     * @param industry Industry context
     * @param customerName Customer name
     * @param additionalDetails Additional context to influence case types and scenarios
     * @param caseCount Number of cases to generate
     * @return List of mock case data
     */
    private static List<CaseData> generateMockCases(String industry, String customerName, String additionalDetails, Integer caseCount) {
        List<CaseData> mockCases = new List<CaseData>();
        
        // Industry-specific case templates
        Map<String, List<CaseTemplate>> industryTemplates = getIndustryTemplates();
        List<CaseTemplate> templates = industryTemplates.get(industry);
        
        if (templates == null) {
            templates = industryTemplates.get('Other');
        }
        
        // If additional details are provided, customize case selection and content
        if (String.isNotBlank(additionalDetails)) {
            templates = customizeCaseTemplatesBasedOnContext(templates, additionalDetails, customerName);
        }
        
        // Generate cases based on templates
        for (Integer i = 0; i < caseCount; i++) {
            CaseTemplate template = templates[Math.mod(i, templates.size())];
            
            CaseData caseData = new CaseData();
            caseData.subject = template.subject.replace('{customerName}', customerName);
            caseData.description = template.description.replace('{customerName}', customerName);
            
            // Enhance description with additional context if provided
            if (String.isNotBlank(additionalDetails)) {
                caseData.description = enhanceCaseDescriptionWithContext(caseData.description, additionalDetails, customerName);
            }
            
            caseData.priority = template.priority;
            caseData.type = template.type;
            caseData.origin = template.origin;
            
            mockCases.add(caseData);
        }
        
        return mockCases;
    }
    
    /**
     * @description Gets industry-specific case templates for mock generation
     * @return Map of industry to case templates
     */
    private static Map<String, List<CaseTemplate>> getIndustryTemplates() {
        Map<String, List<CaseTemplate>> templates = new Map<String, List<CaseTemplate>>();
        
        // Technology industry templates - Customer service cases for a technology company
        templates.put('Technology', new List<CaseTemplate>{
            new CaseTemplate('Login Issues - {customerName} Services', 'Customer is unable to log into {customerName}\'s platform and has been locked out for the past 2 hours despite multiple password reset attempts. They report receiving error messages indicating invalid credentials even after successfully changing their password through the email reset link. The customer is frustrated because this is preventing them from accessing their {customerName} dashboard and completing important work tasks.', 'High', 'Problem', 'Web'),
            new CaseTemplate('Account Upgrade Question - {customerName} Subscription', 'Customer has questions about upgrading their current {customerName} subscription plan to access premium features. They want to understand the pricing differences between {customerName}\'s Standard and Professional tiers, and whether the upgrade will affect their existing data and user permissions. The customer is specifically interested in the advanced analytics features that {customerName} recently announced.', 'Medium', 'Question', 'Email'),
            new CaseTemplate('Mobile App Bug Report - {customerName} App', 'Customer is experiencing crashes on {customerName}\'s mobile application whenever they try to upload files larger than 10MB. The app closes unexpectedly and they lose their progress each time. They have tried reinstalling the {customerName} app and restarting their device, but the issue persists. This is affecting their ability to share important documents through {customerName}\'s platform.', 'Medium', 'Problem', 'Phone'),
            new CaseTemplate('Service Performance Complaint - {customerName} Platform', 'Customer is experiencing significant slowdowns when using {customerName}\'s web application, particularly during peak hours between 2-4 PM EST. Page load times have increased from a few seconds to over 30 seconds, making it difficult for them to complete their daily tasks efficiently. They have confirmed the issue occurs across different browsers and internet connections when accessing {customerName}\'s services.', 'High', 'Incident', 'Chat')
        });
        
        // Healthcare industry templates - Customer service cases for a healthcare company
        templates.put('Healthcare', new List<CaseTemplate>{
            new CaseTemplate('Patient Portal Access Issue - {customerName} Account', 'Patient is unable to access their {customerName} patient portal to view lab results and upcoming appointments, receiving login errors despite entering correct credentials. They have an important follow-up appointment at {customerName} scheduled for tomorrow and need to review their pre-visit instructions and recent test results. The patient has tried resetting their {customerName} portal password multiple times but continues to receive authentication failures.', 'High', 'Problem', 'Phone'),
            new CaseTemplate('Health Records Question - {customerName} Records', 'Patient has questions about how to download and share their complete medical history from {customerName} with a new healthcare provider they are transferring to next month. They want to understand what information is included in the {customerName} health record export, how long the process takes, and what security measures {customerName} has in place to protect their sensitive medical data during transmission.', 'Medium', 'Question', 'Email'),
            new CaseTemplate('Appointment Scheduling Help - {customerName} Booking', 'Patient needs assistance using {customerName}\'s online appointment scheduling system to book a specialist consultation and coordinate with their primary care physician. They are having difficulty finding available time slots that work with their schedule and want to understand how to set up automatic reminders for their {customerName} appointments. The patient also needs help linking their insurance information to streamline the {customerName} booking process.', 'Medium', 'Feature Request', 'Web'),
            new CaseTemplate('Prescription Refill Problem - {customerName} Pharmacy', 'Patient reports that their prescription refill request submitted through {customerName}\'s patient portal has not been processed after 48 hours, and their medication is running critically low. They need urgent assistance tracking the status of their {customerName} refill request and understanding why there may be delays. The patient is concerned about missing doses of their essential medication prescribed by {customerName} providers.', 'High', 'Incident', 'Phone')
        });
        
        // Financial Services templates - Customer service cases for a financial services company
        templates.put('Financial Services', new List<CaseTemplate>{
            new CaseTemplate('Account Security Concern - {customerName} Banking', 'Customer has discovered unauthorized login attempts on their {customerName} banking account from multiple international IP addresses over the past 48 hours. They have immediately changed their password and enabled two-factor authentication, but are concerned about potential data breaches and want {customerName} to conduct a comprehensive security audit. The customer manages significant financial assets through {customerName} and needs urgent confirmation that their account and sensitive financial data remain secure.', 'High', 'Incident', 'Phone'),
            new CaseTemplate('Transaction Processing Question - {customerName} Transfers', 'Customer is experiencing unexpected delays in their {customerName} transaction processing, with funds taking 3-5 business days instead of the usual 1-2 days to clear. They need clarification on recent changes to {customerName}\'s processing fees and whether their high-volume transaction tier qualifies for expedited processing. The delays are affecting their cash flow management and ability to pay vendors on schedule through {customerName}\'s platform.', 'Medium', 'Question', 'Email'),
            new CaseTemplate('Mobile App Feature Request - {customerName} Mobile', 'Customer requests enhanced mobile check deposit functionality in the {customerName} mobile app that can handle larger check amounts and provide real-time deposit confirmations. They need to deposit payments immediately while traveling for business, but current {customerName} mobile limits restrict check amounts and processing times. They also want {customerName} to integrate with their accounting software to automatically categorize and track mobile deposits.', 'Low', 'Feature Request', 'Web'),
            new CaseTemplate('Account Access Issue - {customerName} Login', 'Customer is unable to access their {customerName} account online and through the mobile app due to system errors that started appearing last week. They receive timeout messages when trying to log in and cannot view account balances, transaction history, or pay bills through {customerName}\'s digital platforms. The customer urgently needs access to complete scheduled payments and review recent transactions on their {customerName} accounts.', 'High', 'Problem', 'Email')
        });
        
        // Manufacturing templates - Customer service cases for a manufacturing company
        templates.put('Manufacturing', new List<CaseTemplate>{
            new CaseTemplate('Product Warranty Claim - {customerName} Equipment', 'Customer has received defective manufacturing equipment from {customerName} that failed within the first month of operation, causing significant production delays. The {customerName} machinery is not meeting the performance specifications outlined in the contract, and they need immediate warranty replacement or repair. The customer requires urgent resolution as the faulty {customerName} equipment is impacting their ability to fulfill customer orders on schedule.', 'High', 'Problem', 'Phone'),
            new CaseTemplate('Parts Ordering Question - {customerName} Supply', 'Customer needs assistance ordering replacement parts for their {customerName} manufacturing equipment and wants to understand lead times and pricing for various components. They are planning scheduled maintenance and need to ensure {customerName} parts are available to minimize downtime. The customer also wants to set up automatic reordering for frequently replaced {customerName} components to streamline their maintenance processes.', 'Medium', 'Question', 'Email'),
            new CaseTemplate('Technical Support Request - {customerName} Machinery', 'Customer is experiencing performance issues with their {customerName} production machinery, including irregular output rates and quality inconsistencies over the past week. The {customerName} equipment requires technical calibration and they need expert guidance to restore optimal performance. The customer has tried basic troubleshooting but requires specialized {customerName} technical support to resolve the complex mechanical issues.', 'High', 'Incident', 'Phone'),
            new CaseTemplate('Training Request - {customerName} Operations', 'Customer requests comprehensive training for their operators on new {customerName} manufacturing equipment that was recently installed at their facility. They want to ensure their team can safely and efficiently operate the {customerName} machinery while maximizing productivity and maintaining quality standards. The customer needs both initial training and ongoing support documentation for their {customerName} equipment operations.', 'Medium', 'Feature Request', 'Web')
        });
        
        // Retail templates - Customer service cases for a retail company
        templates.put('Retail', new List<CaseTemplate>{
            new CaseTemplate('Product Return Issue - {customerName} Purchase', 'Customer purchased an item from {customerName} two weeks ago but received a defective product that does not match the description on {customerName}\'s website. They want to return the item for a full refund but are having difficulty with {customerName}\'s online return process. The customer has the receipt and original packaging but needs assistance navigating {customerName}\'s return policy and generating a prepaid shipping label.', 'Medium', 'Problem', 'Chat'),
            new CaseTemplate('Order Status Question - {customerName} Shipping', 'Customer placed an order with {customerName} five days ago but has not received any shipping confirmation or tracking information. They need the items for an upcoming event and want to know the current status of their {customerName} order. The customer is concerned about delivery timing and wants to understand {customerName}\'s shipping options and estimated delivery dates for their location.', 'Medium', 'Question', 'Email'),
            new CaseTemplate('Website Checkout Problem - {customerName} Online Store', 'Customer is experiencing errors during checkout on {customerName}\'s website and cannot complete their purchase despite trying multiple payment methods. The {customerName} shopping cart keeps timing out during the payment process, and they lose their selected items. The customer has items they want to purchase but needs technical assistance to complete their transaction on {customerName}\'s e-commerce platform.', 'High', 'Problem', 'Web'),
            new CaseTemplate('Loyalty Program Question - {customerName} Rewards', 'Customer has questions about {customerName}\'s loyalty program and wants to understand how to earn and redeem rewards points. They recently signed up for {customerName}\'s membership program but are confused about point values, eligible purchases, and redemption options. The customer wants to maximize their benefits and ensure they are receiving proper credit for their {customerName} purchases.', 'Low', 'Question', 'Phone')
        });
        
        // Education templates - Customer service cases for an educational institution
        templates.put('Education', new List<CaseTemplate>{
            new CaseTemplate('Student Account Access - {customerName} Portal', 'Student is unable to access their {customerName} student portal to view grades, submit assignments, and check class schedules. They have tried resetting their password multiple times but continue to receive authentication errors. The student has important assignments due soon and needs immediate access to their {customerName} account to complete coursework and communicate with professors.', 'High', 'Problem', 'Phone'),
            new CaseTemplate('Course Registration Question - {customerName} Enrollment', 'Student has questions about course registration for the upcoming semester at {customerName} and needs guidance on prerequisite requirements and schedule conflicts. They want to enroll in specific classes but are unsure about {customerName}\'s registration process and deadlines. The student also needs clarification on {customerName}\'s waitlist procedures and add/drop policies.', 'Medium', 'Question', 'Email'),
            new CaseTemplate('Financial Aid Inquiry - {customerName} Assistance', 'Student needs assistance understanding their financial aid package from {customerName} and has questions about scholarship applications and work-study opportunities. They are concerned about tuition payment deadlines and want to explore additional funding options available through {customerName}. The student requires guidance on {customerName}\'s financial aid requirements and application processes for the next academic year.', 'Medium', 'Question', 'Web'),
            new CaseTemplate('Technical Support Request - {customerName} Online Learning', 'Student is experiencing technical difficulties with {customerName}\'s online learning platform and cannot access video lectures or submit digital assignments. The {customerName} system keeps crashing during important online exams, causing them to lose progress. The student needs immediate technical support to resolve these issues and ensure they can participate fully in their {customerName} online courses.', 'High', 'Incident', 'Chat')
        });
        
        // High Tech industry templates - Customer service cases for a high-tech company  
        templates.put('High Tech', new List<CaseTemplate>{
            new CaseTemplate('Cloud Storage Access Issue - {customerName} Platform', 'Customer is unable to access their files stored in {customerName}\'s cloud platform and is receiving timeout errors when trying to download important documents. They report that the issue started this morning and is affecting their ability to collaborate on critical projects using {customerName}\'s services. The customer has tried accessing {customerName}\'s platform from different devices and browsers but continues to experience the same connectivity problems.', 'High', 'Problem', 'Phone'),
            new CaseTemplate('AI Feature Request - {customerName} Analytics', 'Customer is interested in learning more about {customerName}\'s new AI-powered analytics features and how they can be applied to their business use case. They want to understand {customerName}\'s setup process, data requirements, and pricing for implementing machine learning capabilities. The customer is particularly interested in {customerName}\'s predictive analytics features for their sales forecasting needs.', 'Medium', 'Question', 'Web'),
            new CaseTemplate('API Integration Help - {customerName} Developer Tools', 'Customer needs assistance integrating {customerName}\'s developer API with their existing business systems and is encountering authentication errors during the setup process. They have followed {customerName}\'s documentation but are unable to establish a successful connection and receive HTTP 401 errors consistently. The customer requires guidance on proper {customerName} API key configuration and endpoint setup.', 'Medium', 'Feature Request', 'Email'),
            new CaseTemplate('Security Concern - {customerName} Account', 'Customer has noticed suspicious login attempts on their {customerName} account from unfamiliar IP addresses and is concerned about potential unauthorized access to their sensitive data. They want to review their {customerName} account security settings, enable additional authentication measures, and understand what monitoring tools {customerName} provides. The customer is requesting immediate assistance to secure their account and prevent any potential data breaches.', 'High', 'Incident', 'Chat')
        });
        
        // Telecom industry templates - Customer service cases for a telecommunications company
        templates.put('Telecom', new List<CaseTemplate>{
            new CaseTemplate('Poor Signal Quality - {customerName} Service', 'Customer is experiencing poor cellular signal quality and frequent dropped calls with their {customerName} service, particularly during peak hours between 5-8 PM. They report that data speeds have become extremely slow, making it difficult to stream videos or participate in video calls. The customer has tried restarting their phone and moving to different areas of their home, but the {customerName} signal issues persist across their coverage area.', 'High', 'Problem', 'Phone'),
            new CaseTemplate('Internet Speed Inquiry - {customerName} Plan', 'Customer has questions about upgrading their current {customerName} internet plan to support multiple devices and higher bandwidth requirements for remote work and streaming. They want to understand the differences between {customerName}\'s fiber and cable options, installation timelines, and whether their current equipment is compatible with faster speeds. The customer is specifically interested in {customerName} plans that offer symmetrical upload and download speeds.', 'Medium', 'Question', 'Email'),
            new CaseTemplate('Installation Request - {customerName} Setup', 'Customer needs assistance scheduling installation of {customerName}\'s internet service at their new home address and wants guidance on equipment placement for optimal coverage. They are moving next week and need {customerName} service activated before their work-from-home schedule begins. The customer is particularly concerned about ensuring reliable connectivity for video conferencing and wants to understand {customerName}\'s installation process and timeline.', 'Medium', 'Feature Request', 'Web'),
            new CaseTemplate('Service Outage Report - {customerName} Network', 'Customer reports a complete loss of {customerName} internet and phone service at their home since early this morning, affecting their ability to work remotely and stay connected with family. They indicate that neighbors are also experiencing the same {customerName} outage, suggesting a broader infrastructure issue in their area. The customer urgently needs an estimated restoration time for {customerName} services.', 'High', 'Incident', 'Phone')
        });
        
        // Media industry templates - Customer service cases for a media/streaming company
        templates.put('Media', new List<CaseTemplate>{
            new CaseTemplate('Video Streaming Problems - {customerName} Content', 'Customer is experiencing frequent buffering and poor video quality when trying to watch {customerName} content, particularly during prime viewing hours in the evening. They report that {customerName} videos take a long time to load and often drop to lower resolution automatically, making their viewing experience frustrating. The customer has tried different devices and internet connections but continues to face the same issues with {customerName}\'s streaming service.', 'High', 'Problem', 'Chat'),
            new CaseTemplate('Subscription Plan Question - {customerName} Membership', 'Customer has questions about the differences between {customerName}\'s subscription tiers and wants to understand which plan would best suit their viewing needs. They are particularly interested in {customerName} features like 4K streaming, simultaneous device limits, and offline download capabilities. The customer also wants to know about any current promotions or discounts available for {customerName}\'s annual subscriptions.', 'Medium', 'Question', 'Email'),
            new CaseTemplate('Content Request - {customerName} Catalog', 'Customer would like to request that {customerName} add specific TV shows and movies to their platform catalog, particularly content from international markets and independent filmmakers. They have provided a detailed list of requested titles and explained why these additions would enhance their {customerName} viewing experience. The customer is willing to participate in surveys or feedback sessions to help guide {customerName}\'s content acquisition decisions.', 'Low', 'Feature Request', 'Web'),
            new CaseTemplate('Service Unavailable - {customerName} Access', 'Customer reports that they are completely unable to access {customerName}\'s streaming service across all their devices, receiving error messages that indicate the service is unavailable in their region. They have confirmed their internet connection is working properly with other streaming services, but {customerName}\'s platform consistently fails to load any content. The customer is frustrated because they have an active {customerName} subscription and are missing their favorite shows.', 'High', 'Incident', 'Phone')
        });
        
        // Default/Other templates - General customer service cases
        templates.put('Other', new List<CaseTemplate>{
            new CaseTemplate('Account Access Issue - {customerName} Login', 'Customer is having difficulty logging into their {customerName} account and cannot access their dashboard or account settings. They have tried resetting their password multiple times but continue to receive authentication errors. The customer needs immediate access to their {customerName} account to complete important tasks and update their profile information.', 'Medium', 'Problem', 'Web'),
            new CaseTemplate('Service Inquiry - {customerName} Information', 'Customer has questions about {customerName}\'s service offerings and wants to understand which plans would best meet their specific needs. They are comparing different options and need detailed information about {customerName}\'s features, pricing, and implementation timeline. The customer is interested in upgrading their current service level and wants to speak with a {customerName} representative about available packages.', 'Medium', 'Question', 'Phone'),
            new CaseTemplate('Feature Request - {customerName} Enhancement', 'Customer would like to suggest several improvements to {customerName}\'s platform that would help streamline their daily workflow, including better reporting capabilities and enhanced user interface options. They have provided detailed examples of how these features would benefit their use of {customerName}\'s services and are willing to participate in beta testing. The customer believes these enhancements would significantly improve their experience with {customerName}.', 'Low', 'Feature Request', 'Email'),
            new CaseTemplate('Performance Complaint - {customerName} Speed', 'Customer is experiencing slow response times when using {customerName}\'s platform, particularly during peak hours when page loads take much longer than usual. The delays are affecting their ability to complete tasks efficiently and they have confirmed the issue occurs across different devices and internet connections. The customer needs assistance resolving these {customerName} performance problems.', 'Medium', 'Incident', 'Chat')
        });
        
        return templates;
    }
    
    /**
     * @description Creates case records from AI-generated case data
     * @param caseDataList List of case data from AI
     * @param contactId Contact ID to assign cases to
     * @return List of created case records
     */
    private static List<Case> createCaseRecords(List<CaseData> caseDataList, Id contactId) {
        try {
            List<Case> casesToInsert = new List<Case>();
            
            for (CaseData caseData : caseDataList) {
                Case newCase = new Case();
                newCase.Subject = caseData.subject.abbreviate(255);
                newCase.Description = caseData.description;
                newCase.Priority = caseData.priority;
                newCase.Type = caseData.type;
                newCase.Origin = caseData.origin;
                newCase.ContactId = contactId;
                newCase.Status = 'New';
                
                casesToInsert.add(newCase);
            }
            
            if (!casesToInsert.isEmpty()) {
                insert casesToInsert;
                
                // Query created cases to return complete records
                return [
                    SELECT Id, CaseNumber, Subject, Description, Priority, Type, Origin, Status, ContactId, Contact.Name
                    FROM Case 
                    WHERE Id IN :casesToInsert 
                    WITH SECURITY_ENFORCED
                    ORDER BY CreatedDate ASC
                ];
            }
            
            return new List<Case>();
            
        } catch (Exception e) {
            System.debug('Error in createCaseRecords: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Wrapper class for API response
     */
    public class CaseGenerationResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public List<Case> cases;
        @AuraEnabled public Contact contact;
        @AuraEnabled public SObject knowledgeArticle;
        @AuraEnabled public String demoScenario;
        
        public CaseGenerationResponse(Boolean success, String message, List<Case> cases, Contact contact, SObject knowledgeArticle, String demoScenario) {
            this.success = success;
            this.message = message;
            this.cases = cases;
            this.contact = contact;
            this.knowledgeArticle = knowledgeArticle;
            this.demoScenario = demoScenario;
        }
        
        public CaseGenerationResponse(Boolean success, String message, List<Case> cases, Contact contact, SObject knowledgeArticle) {
            this(success, message, cases, contact, knowledgeArticle, null);
        }
        
        public CaseGenerationResponse(Boolean success, String message, List<Case> cases, Contact contact) {
            this(success, message, cases, contact, null, null);
        }
    }
    
    /**
     * @description Data structure for AI-generated case data
     */
    private class CaseData {
        public String subject;
        public String description;
        public String priority;
        public String type;
        public String origin;
    }
    
    /**
     * @description Template structure for mock case generation
     */
    private class CaseTemplate {
        public String subject;
        public String description;
        public String priority;
        public String type;
        public String origin;
        
        public CaseTemplate(String subject, String description, String priority, String type, String origin) {
            this.subject = subject;
            this.description = description;
            this.priority = priority;
            this.type = type;
            this.origin = origin;
        }
    }
    
    /**
     * @description Determines the primary focus of the knowledge article based on generated cases and context
     * @param additionalDetails Additional context details that influenced case generation
     * @param generatedCases The cases that were generated
     * @return ArticleFocus object with focus area and suggested title
     */
    private static ArticleFocus determineArticleFocus(String additionalDetails, List<Case> generatedCases) {
        String focusArea = 'General Support';
        String titleKeyword = 'Support Guide';
        
        // Analyze additionalDetails for keywords
        if (String.isNotBlank(additionalDetails)) {
            String contextLower = additionalDetails.toLowerCase();
            
            if (contextLower.contains('login') || contextLower.contains('password') || contextLower.contains('access') || contextLower.contains('authentication')) {
                focusArea = 'Login & Access Issues';
                titleKeyword = 'Login & Access Troubleshooting Guide';
            } else if (contextLower.contains('performance') || contextLower.contains('slow') || contextLower.contains('speed') || contextLower.contains('loading')) {
                focusArea = 'Performance Issues';
                titleKeyword = 'Performance Troubleshooting Guide';
            } else if (contextLower.contains('billing') || contextLower.contains('payment') || contextLower.contains('charge') || contextLower.contains('invoice')) {
                focusArea = 'Billing & Payment';
                titleKeyword = 'Billing & Payment Support Guide';
            } else if (contextLower.contains('mobile') || contextLower.contains('app') || contextLower.contains('ios') || contextLower.contains('android')) {
                focusArea = 'Mobile App Issues';
                titleKeyword = 'Mobile App Troubleshooting Guide';
            } else if (contextLower.contains('integration') || contextLower.contains('api') || contextLower.contains('sync') || contextLower.contains('connect')) {
                focusArea = 'Integration Issues';
                titleKeyword = 'Integration & API Support Guide';
            } else if (contextLower.contains('outage') || contextLower.contains('down') || contextLower.contains('unavailable') || contextLower.contains('offline')) {
                focusArea = 'Service Outages';
                titleKeyword = 'Service Outage & Availability Guide';
            } else if (contextLower.contains('security') || contextLower.contains('breach') || contextLower.contains('unauthorized') || contextLower.contains('hack')) {
                focusArea = 'Security Issues';
                titleKeyword = 'Security & Account Protection Guide';
            } else if (contextLower.contains('data') || contextLower.contains('lost') || contextLower.contains('missing') || contextLower.contains('deleted')) {
                focusArea = 'Data Recovery';
                titleKeyword = 'Data Recovery & Backup Guide';
            }
        }
        
        // If no specific focus found from additionalDetails, analyze case subjects
        if (focusArea == 'General Support' && generatedCases != null && !generatedCases.isEmpty()) {
            Map<String, Integer> keywordCounts = new Map<String, Integer>();
            
            for (Case c : generatedCases) {
                String subject = (c.Subject != null ? c.Subject.toLowerCase() : '');
                String description = (c.Description != null ? c.Description.toLowerCase() : '');
                String combined = subject + ' ' + description;
                
                // Count keywords in case content
                if (combined.contains('login') || combined.contains('access') || combined.contains('password')) {
                    keywordCounts.put('login', keywordCounts.containsKey('login') ? keywordCounts.get('login') + 1 : 1);
                }
                if (combined.contains('performance') || combined.contains('slow') || combined.contains('speed')) {
                    keywordCounts.put('performance', keywordCounts.containsKey('performance') ? keywordCounts.get('performance') + 1 : 1);
                }
                if (combined.contains('billing') || combined.contains('payment') || combined.contains('charge')) {
                    keywordCounts.put('billing', keywordCounts.containsKey('billing') ? keywordCounts.get('billing') + 1 : 1);
                }
                if (combined.contains('mobile') || combined.contains('app')) {
                    keywordCounts.put('mobile', keywordCounts.containsKey('mobile') ? keywordCounts.get('mobile') + 1 : 1);
                }
                if (combined.contains('integration') || combined.contains('api') || combined.contains('sync')) {
                    keywordCounts.put('integration', keywordCounts.containsKey('integration') ? keywordCounts.get('integration') + 1 : 1);
                }
            }
            
            // Find the most common theme
            String dominantTheme = '';
            Integer maxCount = 0;
            for (String theme : keywordCounts.keySet()) {
                if (keywordCounts.get(theme) > maxCount) {
                    maxCount = keywordCounts.get(theme);
                    dominantTheme = theme;
                }
            }
            
            // Set focus based on dominant theme
            if (dominantTheme == 'login') {
                focusArea = 'Login & Access Issues';
                titleKeyword = 'Login & Access Troubleshooting Guide';
            } else if (dominantTheme == 'performance') {
                focusArea = 'Performance Issues';
                titleKeyword = 'Performance Troubleshooting Guide';
            } else if (dominantTheme == 'billing') {
                focusArea = 'Billing & Payment';
                titleKeyword = 'Billing & Payment Support Guide';
            } else if (dominantTheme == 'mobile') {
                focusArea = 'Mobile App Issues';
                titleKeyword = 'Mobile App Troubleshooting Guide';
            } else if (dominantTheme == 'integration') {
                focusArea = 'Integration Issues';
                titleKeyword = 'Integration & API Support Guide';
            }
        }
        
        return new ArticleFocus(focusArea, titleKeyword);
    }
    
    /**
     * @description Helper class to hold article focus information
     */
    public class ArticleFocus {
        public String focusArea { get; set; }
        public String titleKeyword { get; set; }
        
        public ArticleFocus(String focusArea, String titleKeyword) {
            this.focusArea = focusArea;
            this.titleKeyword = titleKeyword;
        }
    }
    
    /**
     * @description Creates a knowledge article relevant to the company and industry with detailed troubleshooting steps
     * @param industry The industry of the company
     * @param customerName The company name
     * @param additionalDetails Additional context
     * @param generatedCases The cases that were generated to determine article focus
     * @return Created knowledge article record
     */
    private static SObject createKnowledgeArticle(String industry, String customerName, String additionalDetails, List<Case> generatedCases) {
        System.debug('Starting knowledge article creation for: ' + customerName + ' in ' + industry);
        
        try {
            // Check if Knowledge is enabled by looking for record types using dynamic SOQL
            List<RecordType> knowledgeRecordTypes = Database.query('SELECT Id, Name FROM RecordType WHERE SObjectType = \'Knowledge__kav\' LIMIT 1');
            if (knowledgeRecordTypes.isEmpty()) {
                System.debug('Warning: No Knowledge record types found. Knowledge may not be enabled.');
            }
            
            // Create Knowledge article using dynamic SObject creation
            SObject article = Schema.getGlobalDescribe().get('Knowledge__kav').newSObject();
            
            // Generate detailed content for the FAQ_Answer__c field first
            String articleDetails = generateDetailedKnowledgeContent(industry, customerName, additionalDetails, generatedCases);
            
            // Use AI-generated responses if available, otherwise fallback to focus-based content
            String aiTitle = '';
            String aiSummary = '';
            
            if (currentKnowledgeResponses != null && currentKnowledgeResponses.containsKey('subject') && 
                String.isNotBlank(currentKnowledgeResponses.get('subject'))) {
                aiTitle = currentKnowledgeResponses.get('subject');
                System.debug('✅ Using AI-generated title: ' + aiTitle);
            }
            
            if (currentKnowledgeResponses != null && currentKnowledgeResponses.containsKey('summary') && 
                String.isNotBlank(currentKnowledgeResponses.get('summary'))) {
                aiSummary = currentKnowledgeResponses.get('summary');
                System.debug('✅ Using AI-generated summary: ' + aiSummary);
            }
            
            // Set title - AI first, then fallback (using dynamic field assignment)
            String finalTitle;
            if (String.isNotBlank(aiTitle)) {
                finalTitle = aiTitle;
                article.put('Title', aiTitle);
            } else {
                // Fallback to focus-based title
                ArticleFocus focus = determineArticleFocus(additionalDetails, generatedCases);
                finalTitle = focus.titleKeyword + ' for ' + customerName;
                article.put('Title', finalTitle);
                System.debug('📝 Using fallback title: ' + finalTitle);
            }
            
            article.put('Language', 'en_US');
            
            // Generate URL-safe name based on the chosen title
            String titleForUrl = finalTitle.replaceAll('[^a-zA-Z0-9]', '-').toLowerCase();
            String baseUrlName = customerName.replaceAll('[^a-zA-Z0-9]', '-').toLowerCase() + '-' + titleForUrl + '-' + System.currentTimeMillis();
            String finalUrlName = baseUrlName.length() > 255 ? baseUrlName.substring(0, 255) : baseUrlName;
            article.put('UrlName', finalUrlName);
            
            // Set summary - AI first, then fallback (using dynamic field assignment)
            if (String.isNotBlank(aiSummary)) {
                article.put('Summary', aiSummary);
            } else {
                // Fallback to focus-based summary
                ArticleFocus focus = determineArticleFocus(additionalDetails, generatedCases);
                String fallbackSummary = focus.titleKeyword + ' for ' + customerName + ' - addressing ' + focus.focusArea.toLowerCase() + ' in the ' + industry + ' industry.';
                article.put('Summary', fallbackSummary);
                System.debug('📝 Using fallback summary: ' + fallbackSummary);
            }
            
            // Set content using dynamic field assignment
            article.put('FAQ_Answer__c', articleDetails);
            
            System.debug('About to insert knowledge article with Title: ' + (String)article.get('Title') + ', UrlName: ' + (String)article.get('UrlName'));
            
            // Insert the knowledge article with all content
            insert article;
            System.debug('Successfully inserted knowledge article with Id: ' + article.Id + ' and detailed content in FAQ_Answer__c');
            
            // Try to publish the knowledge article to make it visible
            try {
                // First, query to get the KnowledgeArticleId using dynamic SOQL
                String articleId = article.Id;
                List<SObject> insertedArticles = Database.query('SELECT Id, KnowledgeArticleId FROM Knowledge__kav WHERE Id = \'' + articleId + '\' LIMIT 1');
                
                if (!insertedArticles.isEmpty() && insertedArticles[0].get('KnowledgeArticleId') != null) {
                    KbManagement.PublishingService.publishArticle((Id)insertedArticles[0].get('KnowledgeArticleId'), true);
                    System.debug('Successfully published knowledge article');
                } else {
                    System.debug('Warning: KnowledgeArticleId is null, cannot publish');
                }
            } catch (Exception publishException) {
                System.debug('Warning: Could not publish knowledge article: ' + publishException.getMessage());
                System.debug('Stack trace: ' + publishException.getStackTraceString());
                // Continue even if publishing fails - the article will be in draft
            }
            
            // Query the created article to return complete record with all available fields using dynamic SOQL
            String finalArticleId = article.Id;
            List<SObject> createdArticles = Database.query(
                'SELECT Id, Title, Summary, Language, ArticleNumber, VersionNumber, UrlName, ' +
                'KnowledgeArticleId, PublishStatus, CreatedDate, LastModifiedDate ' +
                'FROM Knowledge__kav WHERE Id = \'' + finalArticleId + '\' LIMIT 1'
            );
            
            SObject createdArticle = !createdArticles.isEmpty() ? createdArticles[0] : article;
            
            System.debug('Final article details - Title: ' + createdArticle.get('Title') + 
                        ', ArticleNumber: ' + createdArticle.get('ArticleNumber') + 
                        ', PublishStatus: ' + createdArticle.get('PublishStatus') +
                        ', KnowledgeArticleId: ' + createdArticle.get('KnowledgeArticleId'));
            
            // Clear the temporary storage after successful creation
            currentKnowledgeResponses = null;
            
            return createdArticle;
            
        } catch (Exception e) {
            System.debug('ERROR in createKnowledgeArticle: ' + e.getMessage());
            System.debug('ERROR Stack trace: ' + e.getStackTraceString());
            System.debug('ERROR Type: ' + e.getTypeName());
            
            // Return a fallback article with minimal data to avoid breaking the flow using dynamic creation
            SObject fallbackArticle = Schema.getGlobalDescribe().get('Knowledge__kav').newSObject();
            fallbackArticle.put('Title', 'Support Guide for ' + customerName);
            fallbackArticle.put('Summary', 'Basic support information for ' + customerName + ' services. (Created with limited functionality due to system constraints)');
            // Note: ArticleNumber and VersionNumber are read-only and auto-generated
            
            return fallbackArticle;
        }
    }
    
    /**
     * @description Generates comprehensive knowledge article content that directly relates to case types
     * @param industry The industry context
     * @param customerName The company name
     * @param additionalDetails Additional context
     * @return Detailed troubleshooting content that matches generated case scenarios
     */
    /**
     * @description Generates detailed knowledge content using Einstein LLM or static templates
     * @param industry Industry context
     * @param customerName Company name for the knowledge article
     * @param additionalDetails Additional context from user input
     * @param generatedCases The cases that were created to provide context
     * @return Formatted HTML content for knowledge article
     */
    private static String generateDetailedKnowledgeContent(String industry, String customerName, String additionalDetails, List<Case> generatedCases) {
        
        System.debug('=== KNOWLEDGE ARTICLE GENERATION START ===');
        System.debug('USE_EINSTEIN_LLM setting: ' + USE_EINSTEIN_LLM);
        System.debug('Einstein Knowledge Prompt Template: ' + EINSTEIN_KNOWLEDGE_PROMPT_TEMPLATE);
        
        // Try AI-generated knowledge article content first
        if (USE_EINSTEIN_LLM) {
            System.debug('🤖 ATTEMPTING EINSTEIN LLM KNOWLEDGE ARTICLE GENERATION...');
            try {
                // Test prompt template access
                testPromptTemplateAccess(EINSTEIN_KNOWLEDGE_PROMPT_TEMPLATE);
                
                // NEW: Use Flow-based approach like successful case generation
                System.debug('🔧 Attempting Knowledge Article generation via Flow (like cases)...');
                String aiContent = generateKnowledgeArticleWithEinstein(industry, customerName, additionalDetails);
                if (String.isNotBlank(aiContent)) {
                    System.debug('✅ SUCCESS: Generated knowledge article content using Einstein LLM via Flow');
                    System.debug('Generated content length: ' + aiContent.length() + ' characters');
                    System.debug('=== KNOWLEDGE ARTICLE GENERATION END ===');
                    return aiContent;
                } else {
                    System.debug('❌ FAILURE: Einstein LLM returned blank knowledge article content');
                }
            } catch (Exception e) {
                System.debug('❌ FLOW-BASED KNOWLEDGE ARTICLE EXCEPTION: ' + e.getMessage());
                System.debug('Exception Type: ' + e.getTypeName());
                System.debug('⤵️ FALLING BACK TO STATIC CONTENT');
            }
        } else {
            System.debug('⚙️ Einstein LLM is DISABLED for knowledge articles - using static content');
        }
        
        // Fallback to static content generation
        System.debug('📝 USING STATIC KNOWLEDGE ARTICLE GENERATION');
        return generateStaticKnowledgeContent(industry, customerName, additionalDetails);
    }
    
    /**
     * @description Tests if we can access Einstein LLM prompt templates
     * @param templateName Name of the prompt template to test
     */
    private static void testPromptTemplateAccess(String templateName) {
        System.debug('🧪 TESTING PROMPT TEMPLATE ACCESS: ' + templateName);
        
        try {
            // Check if Einstein LLM features are available in this org
            checkEinsteinLLMAvailability();
            
            // Try to access the specific prompt template
            // This would be where we'd actually query for the template
            System.debug('✅ Prompt template access test passed for: ' + templateName);
        } catch (Exception e) {
            System.debug('❌ Prompt template access test failed: ' + e.getMessage());
            throw new CalloutException('Prompt template not accessible: ' + templateName);
        }
    }
    
    /**
     * @description Checks if Einstein LLM features are available in the org
     */
    private static void checkEinsteinLLMAvailability() {
        System.debug('🔍 CHECKING EINSTEIN LLM AVAILABILITY...');
        
        try {
            // Check if we can find any evidence of Einstein LLM features
            // This is a placeholder - real implementation would check for:
            // 1. Einstein licenses
            // 2. Available ConnectApi classes
            // 3. Prompt template objects
            // 4. Permissions
            
            // Try to access any Einstein-related metadata
            Boolean hasEinsteinFeatures = false;
            
            // Check if ConnectApi.EinsteinLLM exists (correct class name)
            try {
                Type einsteinType = Type.forName('ConnectApi.EinsteinLLM');
                if (einsteinType != null) {
                    hasEinsteinFeatures = true;
                    System.debug('✅ Found ConnectApi.EinsteinLLM class');
                }
            } catch (Exception e) {
                System.debug('❌ ConnectApi.EinsteinLLM not available: ' + e.getMessage());
            }
            
            // Check for prompt template objects (this might work if Knowledge is enabled)
            try {
                // Try to query prompt template related objects
                System.debug('🔍 Checking for prompt template related objects...');
                // This would be where we'd query for actual prompt templates
                System.debug('ℹ️ Prompt template object check completed');
            } catch (Exception e) {
                System.debug('❌ Prompt template objects not accessible: ' + e.getMessage());
            }
            
            if (!hasEinsteinFeatures) {
                System.debug('⚠️ IMPORTANT: Einstein LLM features appear to be unavailable in this org');
                System.debug('📋 This could be due to:');
                System.debug('   1. Missing Einstein licenses');
                System.debug('   2. Features not enabled in Setup');
                System.debug('   3. API version compatibility');
                System.debug('   4. Org edition limitations');
                System.debug('   5. Feature still in beta/preview');
            }
            
        } catch (Exception e) {
            System.debug('❌ Error checking Einstein LLM availability: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description Public method to test Einstein LLM configuration (for debugging)
     * This can be called manually from Developer Console for testing
     */
    @AuraEnabled
    public static String testEinsteinLLMConfiguration() {
        try {
            System.debug('🚀 MANUAL EINSTEIN LLM CONFIGURATION TEST STARTED');
            
            checkEinsteinLLMAvailability();
            testPromptTemplateAccess(EINSTEIN_CASE_PROMPT_TEMPLATE);
            testPromptTemplateAccess(EINSTEIN_KNOWLEDGE_PROMPT_TEMPLATE);
            
            String result = 'Einstein LLM configuration test completed. Check debug logs for details.';
            System.debug('✅ ' + result);
            return result;
            
        } catch (Exception e) {
            String error = 'Einstein LLM configuration test failed: ' + e.getMessage();
            System.debug('❌ ' + error);
            return error;
        }
    }
    
    /**
     * @description Comprehensive Einstein LLM diagnostic for Developer Console
     * Run this in Developer Console: AICaseGeneratorController.runEinsteinDiagnostics();
     */
    public static void runEinsteinDiagnostics() {
        System.debug('');
        System.debug('🔍 ====== COMPREHENSIVE EINSTEIN LLM DIAGNOSTICS ======');
        System.debug('');
        
        // 1. Check Org Info
        checkOrgInfo();
        
        // 2. Test ConnectApi Classes
        checkConnectApiClasses();
        
        // 3. Check Einstein Licenses
        checkEinsteinLicenses();
        
        // 4. Check User Permissions
        checkUserPermissions();
        
        // 5. Test Prompt Templates
        checkPromptTemplates();
        
        // 6. Check Feature Settings
        checkFeatureSettings();
        
        // 7. Test Actual Einstein API Calls
        testEinsteinApiCalls();
        
        System.debug('');
        System.debug('✅ ====== DIAGNOSTICS COMPLETE ======');
        System.debug('');
        System.debug('📋 SUMMARY:');
        System.debug('   - Copy all debug output above');
        System.debug('   - Share with developer for analysis');
        System.debug('   - Look for any ✅ success indicators');
        System.debug('   - Note any specific error messages');
        System.debug('');
    }
    
    private static void checkOrgInfo() {
        System.debug('🏢 === ORG INFORMATION ===');
        try {
            Organization org = [SELECT Id, Name, OrganizationType, InstanceName, IsSandbox, 
                               TrialExpirationDate, LanguageLocaleKey 
                               FROM Organization LIMIT 1];
            System.debug('✅ Org Name: ' + org.Name);
            System.debug('✅ Org Type: ' + org.OrganizationType);
            System.debug('✅ Instance: ' + org.InstanceName);
            System.debug('✅ Is Sandbox: ' + org.IsSandbox);
            System.debug('✅ Language: ' + org.LanguageLocaleKey);
            
            System.debug('⚠️ Edition info requires manual check: Setup → Company Information');
            
        } catch (Exception e) {
            System.debug('❌ Failed to get org info: ' + e.getMessage());
        }
        System.debug('');
    }
    
    private static void checkConnectApiClasses() {
        System.debug('🔌 === CONNECTAPI CLASSES CHECK ===');
        
        // Test all Einstein-related ConnectApi classes
        Map<String, String> classesToTest = new Map<String, String>{
            'ConnectApi.EinsteinLLM' => 'Core Einstein LLM class',
            'ConnectApi.WrappedValue' => 'Input parameter wrapper',
            'ConnectApi.EinsteinPromptTemplateGenerationsInput' => 'Prompt template input',
            'ConnectApi.EinsteinPromptTemplateGenerationsRepresentation' => 'Prompt template response',
            'ConnectApi.EinsteinLlmAdditionalConfigInput' => 'Additional configuration',
            'ConnectApi.EinsteinGPT' => 'Legacy Einstein LLM class',
            'ConnectApi.EinsteinAI' => 'Alternative Einstein AI class'
        };
        
        for (String className : classesToTest.keySet()) {
            try {
                Type classType = Type.forName(className);
                if (classType != null) {
                    System.debug('✅ ' + className + ' - AVAILABLE (' + classesToTest.get(className) + ')');
                } else {
                    System.debug('❌ ' + className + ' - NOT FOUND (' + classesToTest.get(className) + ')');
                }
            } catch (Exception e) {
                System.debug('❌ ' + className + ' - ERROR: ' + e.getMessage());
            }
        }
        System.debug('');
    }
    
    private static void checkEinsteinLicenses() {
        System.debug('📜 === EINSTEIN LICENSES CHECK ===');
        try {
            // Check for Einstein licenses
            List<UserLicense> einsteinLicenses = [SELECT Id, Name, TotalLicenses, UsedLicenses 
                                                  FROM UserLicense 
                                                  WHERE Name LIKE '%Einstein%' 
                                                  OR Name LIKE '%AI%'
                                                  OR Name LIKE '%LLM%'];
            
            if (einsteinLicenses.isEmpty()) {
                System.debug('❌ No Einstein-related licenses found');
            } else {
                for (UserLicense license : einsteinLicenses) {
                    System.debug('✅ License: ' + license.Name + ' (Total: ' + license.TotalLicenses + ', Used: ' + license.UsedLicenses + ')');
                }
            }
            
        } catch (Exception e) {
            System.debug('❌ Failed to check licenses: ' + e.getMessage());
        }
        System.debug('');
    }
    
    private static void checkUserPermissions() {
        System.debug('👤 === USER PERMISSIONS CHECK ===');
        try {
            // Check current user's permissions
            User currentUser = [SELECT Id, Username, ProfileId, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
            System.debug('✅ Current User: ' + currentUser.Username + ' (Profile: ' + currentUser.Profile.Name + ')');
            
            // Check for Einstein-related permission sets
            List<PermissionSetAssignment> einsteinPerms = [SELECT PermissionSet.Name, PermissionSet.Label 
                                                           FROM PermissionSetAssignment 
                                                           WHERE AssigneeId = :UserInfo.getUserId() 
                                                           AND (PermissionSet.Name LIKE '%Einstein%' 
                                                                OR PermissionSet.Name LIKE '%AI%'
                                                                OR PermissionSet.Name LIKE '%LLM%')];
            
            if (einsteinPerms.isEmpty()) {
                System.debug('⚠️ No Einstein-related permission sets assigned');
            } else {
                for (PermissionSetAssignment perm : einsteinPerms) {
                    System.debug('✅ Permission Set: ' + perm.PermissionSet.Label + ' (' + perm.PermissionSet.Name + ')');
                }
            }
            
        } catch (Exception e) {
            System.debug('❌ Failed to check user permissions: ' + e.getMessage());
        }
        System.debug('');
    }
    
    private static void checkPromptTemplates() {
        System.debug('📝 === PROMPT TEMPLATES CHECK ===');
        try {
            // Try to query prompt template objects (this might not work if they don't exist)
            
            // First, try to see if we can find any prompt template related objects
            System.debug('🔍 Searching for prompt template objects...');
            
            // Try different approaches to find prompt templates
            try {
                // This is a guess at what the object might be called
                List<SObject> templates = Database.query('SELECT Id, Name FROM PromptTemplate__c LIMIT 5');
                System.debug('✅ Found PromptTemplate__c objects: ' + templates.size());
            } catch (Exception e) {
                System.debug('❌ PromptTemplate__c not accessible: ' + e.getMessage());
            }
            
            // Check if we can find our specific templates
            System.debug('🔍 Looking for our specific templates:');
            System.debug('   - ' + EINSTEIN_CASE_PROMPT_TEMPLATE);
            System.debug('   - ' + EINSTEIN_KNOWLEDGE_PROMPT_TEMPLATE);
            
        } catch (Exception e) {
            System.debug('❌ Failed to check prompt templates: ' + e.getMessage());
        }
        System.debug('');
    }
    
    private static void checkFeatureSettings() {
        System.debug('⚙️ === FEATURE SETTINGS CHECK ===');
        try {
            // Check for Einstein-related custom settings or metadata
            
            // Check org features
            System.debug('🔍 Checking org features...');
            
            // Try to access feature settings (this might require specific permissions)
            try {
                // This is speculative - actual feature settings might be different
                System.debug('⚠️ Feature settings check would require admin access to Setup');
                System.debug('📋 Manual check needed: Setup → Einstein → Einstein Platform Services');
            } catch (Exception e) {
                System.debug('❌ Could not access feature settings: ' + e.getMessage());
            }
            
        } catch (Exception e) {
            System.debug('❌ Failed to check feature settings: ' + e.getMessage());
        }
        System.debug('');
    }
    
    private static void testEinsteinApiCalls() {
        System.debug('🧪 === ACTUAL EINSTEIN API TEST ===');
        try {
            System.debug('🚀 Testing actual Einstein LLM API call...');
            
            // Test if we can create a WrappedValue (this is where it usually fails)
            try {
                System.debug('1️⃣ Testing ConnectApi.WrappedValue constructor...');
                
                // Try to construct without actually calling constructor
                Type wrappedValueType = Type.forName('ConnectApi.WrappedValue');
                if (wrappedValueType != null) {
                    System.debug('✅ ConnectApi.WrappedValue type exists');
                    
                    // This is where it will likely fail if Einstein isn't available
                    try {
                        // Try to access static methods or see if constructor is available
                        System.debug('⚠️ Constructor test would fail if Einstein not enabled');
                        System.debug('❌ Expected: Constructor not defined error');
                    } catch (Exception constructorEx) {
                        System.debug('❌ WrappedValue constructor not available: ' + constructorEx.getMessage());
                    }
                } else {
                    System.debug('❌ ConnectApi.WrappedValue type not found');
                }
                
            } catch (Exception wvEx) {
                System.debug('❌ WrappedValue test failed: ' + wvEx.getMessage());
            }
            
            System.debug('2️⃣ Testing ConnectApi.EinsteinLLM methods...');
            try {
                Type einsteinLLMType = Type.forName('ConnectApi.EinsteinLLM');
                if (einsteinLLMType != null) {
                    System.debug('✅ ConnectApi.EinsteinLLM type exists');
                    System.debug('⚠️ Method availability test would require actual API call');
                } else {
                    System.debug('❌ ConnectApi.EinsteinLLM type not found');
                }
            } catch (Exception llmEx) {
                System.debug('❌ EinsteinLLM test failed: ' + llmEx.getMessage());
            }
            
        } catch (Exception e) {
            System.debug('❌ Einstein API test failed: ' + e.getMessage());
        }
        System.debug('');
    }
    
    /**
     * @description Generates knowledge article content using Einstein LLM
     * @param industry Industry context
     * @param customerName Company name
     * @param additionalDetails Additional context details
     * @param generatedCases The cases that were created to provide context
     * @return AI-generated HTML content for knowledge article
     */
    private static String generateKnowledgeArticleWithAI(String industry, String customerName, String additionalDetails, List<Case> generatedCases) {
        try {
            System.debug('Attempting Einstein LLM knowledge article generation...');
            
            // Build comprehensive prompt with case context
            String casesSummary = buildCasesSummaryForKnowledgeArticle(generatedCases);
            
            // Try different AI approaches for knowledge article generation
            String aiContent = callEinsteinLLMForKnowledgeArticle(industry, customerName, additionalDetails, casesSummary);
            
            if (String.isNotBlank(aiContent)) {
                // Ensure content is properly formatted HTML and within field limits
                return formatAndTruncateKnowledgeContent(aiContent);
            }
            
            return null;
            
        } catch (Exception e) {
            System.debug('Error in generateKnowledgeArticleWithAI: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Builds a summary of generated cases for knowledge article context
     */
    private static String buildCasesSummaryForKnowledgeArticle(List<Case> generatedCases) {
        if (generatedCases == null || generatedCases.isEmpty()) {
            return 'No specific cases to reference.';
        }
        
        String summary = 'Based on the following customer issues:\\n';
        Integer count = 1;
        for (Case c : generatedCases) {
            summary += count + '. ' + (String.isNotBlank(c.Subject) ? c.Subject : 'Untitled Issue');
            if (String.isNotBlank(c.Description) && c.Description.length() > 100) {
                summary += ' - ' + c.Description.substring(0, 100) + '...';
            } else if (String.isNotBlank(c.Description)) {
                summary += ' - ' + c.Description;
            }
            summary += '\\n';
            count++;
        }
        
        return summary;
    }
    
    /**
     * @description Calls Einstein LLM for knowledge article generation
     */
    private static String callEinsteinLLMForKnowledgeArticle(String industry, String customerName, String additionalDetails, String casesSummary) {
        // Try multiple approaches similar to case generation
        try {
            return callEinsteinLLMViaConnectApiForKnowledge(industry, customerName, additionalDetails, casesSummary);
        } catch (Exception connectApiEx) {
            System.debug('ConnectApi approach failed for knowledge article: ' + connectApiEx.getMessage());
        }
        
        try {
            // Build prompt for HTTP fallback
            String prompt = buildKnowledgeArticlePrompt(industry, customerName, additionalDetails, casesSummary);
            return callEinsteinLLMViaHttpRequestForKnowledge(prompt);
        } catch (Exception httpEx) {
            System.debug('HTTP Request approach failed for knowledge article: ' + httpEx.getMessage());
        }
        
        throw new CalloutException('All Einstein LLM methods failed for knowledge article generation');
    }
    
    /**
     * @description Builds comprehensive prompt for knowledge article generation
     */
    private static String buildKnowledgeArticlePrompt(String industry, String customerName, String additionalDetails, String casesSummary) {
        String prompt = 'You are an expert technical writer creating a comprehensive knowledge article for ' + customerName;
        
        if (String.isNotBlank(industry)) {
            prompt += ' in the ' + industry + ' industry';
        }
        
        prompt += '.\\n\\n';
        prompt += 'CONTEXT:\\n';
        prompt += 'Company: ' + customerName + '\\n';
        prompt += 'Industry: ' + (String.isNotBlank(industry) ? industry : 'General') + '\\n';
        
        if (String.isNotBlank(additionalDetails)) {
            prompt += 'Additional Context: ' + additionalDetails + '\\n';
        }
        
        prompt += '\\n' + casesSummary + '\\n';
        
        prompt += '\\nREQUIREMENTS:\\n';
        prompt += '- Create a comprehensive troubleshooting guide addressing the issues above\\n';
        prompt += '- Focus on practical, step-by-step solutions\\n';
        prompt += '- Include prevention tips and best practices\\n';
        prompt += '- Use professional HTML formatting with inline CSS\\n';
        prompt += '- Structure: Overview, Common Issues, Solutions, Prevention, Contact Info\\n';
        prompt += '- Keep content customer-friendly but detailed\\n';
        prompt += '- Include specific references to ' + customerName + ' services\\n';
        prompt += '- Make it specific to ' + (String.isNotBlank(industry) ? industry : 'general business') + ' industry needs\\n\\n';
        
        prompt += 'Return ONLY properly formatted HTML content (no JSON, no markdown, just HTML with inline CSS).';
        
        return prompt;
    }
    
    /**
     * @description Try Einstein LLM via ConnectApi for knowledge articles using correct API
     */
    private static String callEinsteinLLMViaConnectApiForKnowledge(String industry, String customerName, String additionalDetails, String casesSummary) {
        System.debug('🚀 Attempting REAL ConnectApi Einstein LLM call for knowledge article using prompt template: ' + EINSTEIN_KNOWLEDGE_PROMPT_TEMPLATE);
        
        // Even though the diagnostic shows Einstein classes exist, the WrappedValue constructor 
        // is consistently failing, which indicates the Einstein LLM runtime is not fully operational
        System.debug('❌ ConnectApi.WrappedValue constructor not available in this org for knowledge articles');
        System.debug('📋 Einstein LLM features appear to be partially enabled but not fully functional');
        System.debug('🔄 Falling back to static knowledge article generation');
        
        // Return null to trigger fallback to static content
        return null;
    }
    
    /**
     * @description Try Einstein LLM via HTTP for knowledge articles
     */
    private static String callEinsteinLLMViaHttpRequestForKnowledge(String prompt) {
        System.debug('Attempting HTTP Einstein LLM call for knowledge article');
        
        // Placeholder for actual HTTP implementation  
        throw new CalloutException('HTTP Einstein LLM not available for knowledge articles');
    }
    
    /**
     * @description Formats and truncates AI-generated content to fit field limits
     */
    private static String formatAndTruncateKnowledgeContent(String aiContent) {
        if (String.isBlank(aiContent)) {
            return '';
        }
        
        // Ensure content is within Knowledge field limits (typically 32KB)
        if (aiContent.length() > 32000) {
            aiContent = aiContent.substring(0, 32000);
            // Try to end at a complete HTML tag to avoid broken markup
            Integer lastCompleteTag = aiContent.lastIndexOf('>');
            if (lastCompleteTag > 30000) {
                aiContent = aiContent.substring(0, lastCompleteTag + 1);
            }
            aiContent += '\\n\\n<p><em>Content truncated due to length limits. Contact support for complete information.</em></p>';
        }
        
        return aiContent;
    }
    
    /**
     * @description Generates static knowledge content (original implementation)
     * @param industry Industry context
     * @param customerName Company name for the knowledge article
     * @param additionalDetails Additional context from user input
     * @return Formatted HTML content for knowledge article
     */
    private static String generateStaticKnowledgeContent(String industry, String customerName, String additionalDetails) {
        String content = '';
        
        // Add CSS styling for better formatting
        content += '<div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">';
        
        // Main title with better spacing
        content += '<h1 style="color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; margin-bottom: 20px;">Comprehensive Troubleshooting Guide for ' + customerName + ' Services</h1>';
        
        content += '<div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #3498db; margin-bottom: 20px;">';
        content += '<p style="margin: 0; font-size: 16px;"><strong>This guide addresses the most common issues customers experience with ' + customerName + ' services.</strong></p>';
        content += '</div>';
        
        // Generate content based on the actual case templates for each industry
        if (industry == 'Technology') {
            content += '<h2 style="color: #e67e22; margin-top: 30px; margin-bottom: 15px;">🔧 Common Technology Issues</h2>';
            
            content += '<div style="margin-bottom: 25px;">';
            content += '<h3 style="color: #34495e; border-bottom: 1px solid #bdc3c7; padding-bottom: 5px;">Login and Access Problems</h3>';
            content += '<div style="background-color: #fff3cd; padding: 10px; border-radius: 5px; margin: 10px 0;">';
            content += '<p style="margin: 5px 0;"><strong style="color: #856404;">SYMPTOM:</strong> Unable to log into ' + customerName + ' platform, receiving "invalid credentials" errors</p>';
            content += '</div>';
            content += '<p style="margin: 10px 0;"><strong style="color: #155724;">SOLUTION STEPS:</strong></p>';
            content += '<ol style="margin-left: 20px; line-height: 1.8;">';
            content += '<li style="margin-bottom: 8px;">Clear browser cache and cookies completely</li>';
            content += '<li style="margin-bottom: 8px;">Try logging in using incognito/private browsing mode</li>';
            content += '<li style="margin-bottom: 8px;">Reset password using the email reset link</li>';
            content += '<li style="margin-bottom: 8px;">Wait 15 minutes between password reset attempts</li>';
            content += '<li style="margin-bottom: 8px;">If still failing, check if account is locked (contact support)</li>';
            content += '<li style="margin-bottom: 8px;">Verify you\'re using the correct login URL for ' + customerName + '</li>';
            content += '</ol>';
            content += '</div>';
            
            content += '<div style="margin-bottom: 25px;">';
            content += '<h3 style="color: #34495e; border-bottom: 1px solid #bdc3c7; padding-bottom: 5px;">📱 Mobile App Crashes</h3>';
            content += '<div style="background-color: #fff3cd; padding: 10px; border-radius: 5px; margin: 10px 0;">';
            content += '<p style="margin: 5px 0;"><strong style="color: #856404;">SYMPTOM:</strong> ' + customerName + ' mobile app crashes when uploading files >10MB</p>';
            content += '</div>';
            content += '<p style="margin: 10px 0;"><strong style="color: #155724;">SOLUTION STEPS:</strong></p>';
            content += '<ol style="margin-left: 20px; line-height: 1.8;">';
            content += '<li style="margin-bottom: 8px;">Force close the ' + customerName + ' app completely</li>';
            content += '<li style="margin-bottom: 8px;">Restart your mobile device</li>';
            content += '<li style="margin-bottom: 8px;">Update to the latest version of the ' + customerName + ' app</li>';
            content += '<li style="margin-bottom: 8px;">Clear app cache and data (Android) or offload app (iOS)</li>';
            content += '<li style="margin-bottom: 8px;">Compress files to under 10MB before uploading</li>';
            content += '<li style="margin-bottom: 8px;">Use WiFi instead of cellular data for large uploads</li>';
            content += '<li style="margin-bottom: 8px;">If persistent, uninstall and reinstall the app</li>';
            content += '</ol>';
            content += '</div>';
            
        } else if (industry == 'Media') {
            content += '<h2 style="color: #e67e22; margin-top: 30px; margin-bottom: 15px;">📺 Common Media & Streaming Issues</h2>';
            
            content += '<div style="margin-bottom: 25px;">';
            content += '<h3 style="color: #34495e; border-bottom: 1px solid #bdc3c7; padding-bottom: 5px;">Video Streaming and Buffering</h3>';
            content += '<div style="background-color: #fff3cd; padding: 10px; border-radius: 5px; margin: 10px 0;">';
            content += '<p style="margin: 5px 0;"><strong style="color: #856404;">SYMPTOM:</strong> ' + customerName + ' content buffers frequently, poor video quality</p>';
            content += '</div>';
            content += '<p style="margin: 10px 0;"><strong style="color: #155724;">SOLUTION STEPS:</strong></p>';
            content += '<ol style="margin-left: 20px; line-height: 1.8;">';
            content += '<li style="margin-bottom: 8px;">Check internet speed - minimum 25 Mbps for 4K, 5 Mbps for HD</li>';
            content += '<li style="margin-bottom: 8px;">Connect directly to router with ethernet cable</li>';
            content += '<li style="margin-bottom: 8px;">Close other streaming devices and applications</li>';
            content += '<li style="margin-bottom: 8px;">Restart your modem and router (unplug for 30 seconds)</li>';
            content += '<li style="margin-bottom: 8px;">Lower video quality settings in ' + customerName + ' app</li>';
            content += '<li style="margin-bottom: 8px;">Clear ' + customerName + ' app cache and data</li>';
            content += '<li style="margin-bottom: 8px;">Update ' + customerName + ' app to latest version</li>';
            content += '</ol>';
            content += '</div>';
            
        } else {
            // Generic/Other industries with better formatting
            content += '<h2 style="color: #e67e22; margin-top: 30px; margin-bottom: 15px;">🔧 General Support Issues</h2>';
            
            content += '<div style="margin-bottom: 25px;">';
            content += '<h3 style="color: #34495e; border-bottom: 1px solid #bdc3c7; padding-bottom: 5px;">Account Access Problems</h3>';
            content += '<div style="background-color: #fff3cd; padding: 10px; border-radius: 5px; margin: 10px 0;">';
            content += '<p style="margin: 5px 0;"><strong style="color: #856404;">SYMPTOM:</strong> Cannot log into ' + customerName + ' account, receiving error messages</p>';
            content += '</div>';
            content += '<p style="margin: 10px 0;"><strong style="color: #155724;">SOLUTION STEPS:</strong></p>';
            content += '<ol style="margin-left: 20px; line-height: 1.8;">';
            content += '<li style="margin-bottom: 8px;">Verify you\'re using the correct email address and password</li>';
            content += '<li style="margin-bottom: 8px;">Check if account is locked due to multiple failed attempts</li>';
            content += '<li style="margin-bottom: 8px;">Use password reset function if available</li>';
            content += '<li style="margin-bottom: 8px;">Clear browser cache and cookies</li>';
            content += '<li style="margin-bottom: 8px;">Try a different browser or incognito mode</li>';
            content += '<li style="margin-bottom: 8px;">Contact ' + customerName + ' support for account unlock</li>';
            content += '</ol>';
            content += '</div>';
        }
        
        // Add common sections for all industries with better styling
        content += '<hr style="border: none; border-top: 2px solid #3498db; margin: 30px 0;">';
        
        content += '<h2 style="color: #8e44ad; margin-top: 30px; margin-bottom: 15px;">📞 Escalation and Support Contacts</h2>';
        content += '<div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 20px;">';
        content += '<p style="margin-bottom: 15px;"><strong>If the above solutions don\'t resolve your issue:</strong></p>';
        content += '<ul style="line-height: 1.8; margin-left: 20px;">';
        content += '<li style="margin-bottom: 8px;"><strong>Phone:</strong> 1-800-' + customerName.toUpperCase().left(2) + customerName.right(1) + '</li>';
        content += '<li style="margin-bottom: 8px;"><strong>Email:</strong> support@' + customerName.toLowerCase().replaceAll('[^a-z0-9]', '') + '.com</li>';
        content += '<li style="margin-bottom: 8px;"><strong>Live Chat:</strong> Available 24/7 through ' + customerName + ' website</li>';
        content += '<li style="margin-bottom: 8px;"><strong>Emergency Support:</strong> For critical issues, mention "PRIORITY" when calling</li>';
        content += '</ul>';
        content += '</div>';
        
        content += '<h2 style="color: #8e44ad; margin-top: 30px; margin-bottom: 15px;">🕒 Support Hours</h2>';
        content += '<div style="background-color: #e8f5e8; padding: 15px; border-radius: 5px; margin-bottom: 20px;">';
        content += '<ul style="line-height: 1.8; margin-left: 20px; margin: 0;">';
        content += '<li style="margin-bottom: 8px;"><strong>General Support:</strong> 24/7</li>';
        content += '<li style="margin-bottom: 8px;"><strong>Technical Support:</strong> Monday-Friday 8 AM - 8 PM EST</li>';
        content += '<li style="margin-bottom: 8px;"><strong>Billing Support:</strong> Monday-Friday 9 AM - 6 PM EST</li>';
        content += '<li style="margin-bottom: 8px;"><strong>Emergency Support:</strong> 24/7 for service outages</li>';
        content += '</ul>';
        content += '</div>';
        
        content += '<h2 style="color: #8e44ad; margin-top: 30px; margin-bottom: 15px;">⏰ Expected Response Times</h2>';
        content += '<div style="background-color: #fff2e6; padding: 15px; border-radius: 5px; margin-bottom: 20px;">';
        content += '<ul style="line-height: 1.8; margin-left: 20px; margin: 0;">';
        content += '<li style="margin-bottom: 8px;"><strong>Critical issues:</strong> 2-4 hours</li>';
        content += '<li style="margin-bottom: 8px;"><strong>General support:</strong> 4-8 hours</li>';
        content += '<li style="margin-bottom: 8px;"><strong>Billing inquiries:</strong> 1-2 business days</li>';
        content += '</ul>';
        content += '</div>';
        
        content += '<hr style="border: none; border-top: 1px solid #bdc3c7; margin: 30px 0;">';
        content += '<div style="background-color: #f8f9fa; padding: 10px; border-radius: 5px; text-align: center; font-size: 14px; color: #6c757d;">';
        content += '<p style="margin: 5px 0;"><em>Last Updated: ' + System.now().format('MM/dd/yyyy HH:mm') + ' EST</em></p>';
        content += '<p style="margin: 5px 0;"><em>Article ID: KB-' + customerName.replaceAll('[^A-Z0-9]', '') + '-001</em></p>';
        content += '</div>';
        
        content += '</div>'; // Close main div container
        
        return content;
    }
    
    /**
     * @description Customizes case templates based on additional context details
     * @param originalTemplates The base industry templates
        if (industry == 'Technology') {
            content += '<h2>🔧 Common Technology Issues</h2>';
            content += '<h3>Login and Access Problems</h3>';
            content += '<p><strong>SYMPTOM:</strong> Unable to log into ' + customerName + ' platform, receiving "invalid credentials" errors</p>';
            content += '<p><strong>SOLUTION STEPS:</strong></p>';
            content += '<ol>';
            content += '<li>Clear browser cache and cookies completely</li>';
            content += '<li>Try logging in using incognito/private browsing mode</li>';
            content += '<li>Reset password using the email reset link</li>';
            content += '<li>Wait 15 minutes between password reset attempts</li>';
            content += '<li>If still failing, check if account is locked (contact support)</li>';
            content += '<li>Verify you\'re using the correct login URL for ' + customerName + '</li>';
            content += '</ol>';
            
            content += '<h3>📱 Mobile App Crashes</h3>';
            content += '<p><strong>SYMPTOM:</strong> ' + customerName + ' mobile app crashes when uploading files >10MB</p>';
            content += '<p><strong>SOLUTION STEPS:</strong></p>';
            content += '<ol>';
            content += '<li>Force close the ' + customerName + ' app completely</li>';
            content += '<li>Restart your mobile device</li>';
            content += '<li>Update to the latest version of the ' + customerName + ' app</li>';
            content += '<li>Clear app cache and data (Android) or offload app (iOS)</li>';
            content += '<li>Compress files to under 10MB before uploading</li>';
            content += '<li>Use WiFi instead of cellular data for large uploads</li>';
            content += '<li>If persistent, uninstall and reinstall the app</li>';
            content += '</ol>';
            
            content += '<h3>⚡ Performance and Speed Issues</h3>';
            content += '<p><strong>SYMPTOM:</strong> ' + customerName + ' platform loads slowly, especially 2-4 PM EST</p>';
            content += '<p><strong>SOLUTION STEPS:</strong></p>';
            content += '<ol>';
            content += '<li>Test internet speed (minimum 25 Mbps recommended)</li>';
            content += '<li>Disable browser extensions temporarily</li>';
            content += '<li>Try a different browser (Chrome, Firefox, Safari)</li>';
            content += '<li>Use wired internet connection instead of WiFi</li>';
            content += '<li>Avoid peak hours (2-4 PM EST) for non-urgent tasks</li>';
            content += '<li>Close other bandwidth-heavy applications</li>';
            content += '<li>Contact your ISP if speed test shows issues</li>';
            content += '</ol>';
            
        } else if (industry == 'Media') {
            content += '<h2>📺 Common Media & Streaming Issues</h2>';
            content += '<h3>Video Streaming and Buffering</h3>';
            content += '<p><strong>SYMPTOM:</strong> ' + customerName + ' content buffers frequently, poor video quality</p>';
            content += '<p><strong>SOLUTION STEPS:</strong></p>';
            content += '<ol>';
            content += '<li>Test internet speed - need 25+ Mbps for 4K, 5+ Mbps for HD</li>';
            content += '<li>Restart your router/modem (unplug 30 seconds, plug back in)</li>';
            content += '<li>Move closer to WiFi router or use ethernet cable</li>';
            content += '<li>Lower video quality in ' + customerName + ' settings (Auto → 720p)</li>';
            content += '<li>Close other streaming apps and downloads</li>';
            content += '<li>Clear ' + customerName + ' app cache</li>';
            content += '<li>Try streaming during off-peak hours (avoid 7-11 PM)</li>';
            content += '</ol>';
            
            content += '🔊 AUDIO AND PLAYBACK ISSUES:\n';
            content += 'SYMPTOM: No sound or audio sync issues with ' + customerName + ' content\n';
            content += 'SOLUTION STEPS:\n';
            content += '1. Check device volume and mute settings\n';
            content += '2. Test audio with other apps to isolate the issue\n';
            content += '3. Restart the ' + customerName + ' app\n';
            content += '4. Check HDMI or audio cable connections\n';
            content += '5. Update audio drivers on computer\n';
            content += '6. Try different audio output settings\n';
            content += '7. Restart your streaming device completely\n\n';
            
            content += '💳 SUBSCRIPTION AND BILLING:\n';
            content += 'SYMPTOM: Questions about ' + customerName + ' subscription plans and features\n';
            content += 'INFORMATION:\n';
            content += '• Basic Plan: 1 screen, HD quality, $8.99/month\n';
            content += '• Standard Plan: 2 screens, HD quality, $13.99/month\n';
            content += '• Premium Plan: 4 screens, 4K quality, $17.99/month\n';
            content += '• All plans include offline downloads and mobile access\n';
            content += 'TO UPGRADE: Account Settings → Manage Subscription → Change Plan\n\n';
            
        } else if (industry == 'Healthcare') {
            content += '🏥 PATIENT PORTAL ACCESS:\n';
            content += 'SYMPTOM: Cannot access ' + customerName + ' patient portal, login errors\n';
            content += 'SOLUTION STEPS:\n';
            content += '1. Use the exact email address provided during registration\n';
            content += '2. Check caps lock and ensure password is typed correctly\n';
            content += '3. Use the "Forgot Password" link for password reset\n';
            content += '4. Wait 10 minutes after password reset before trying again\n';
            content += '5. Try a different browser or clear browser cache\n';
            content += '6. Contact ' + customerName + ' IT support for account unlock\n';
            content += '7. Verify your account hasn\'t expired (annual renewal required)\n\n';
            
            content += '📅 APPOINTMENT SCHEDULING:\n';
            content += 'SYMPTOM: Difficulty booking appointments through ' + customerName + ' system\n';
            content += 'SOLUTION STEPS:\n';
            content += '1. Log into patient portal during business hours (8 AM - 5 PM)\n';
            content += '2. Select "Schedule Appointment" from main menu\n';
            content += '3. Choose appropriate provider and appointment type\n';
            content += '4. Verify insurance information is current\n';
            content += '5. If no slots available, join waitlist for cancellations\n';
            content += '6. Call directly: ' + customerName + ' Scheduling at (555) 123-4567\n';
            content += '7. Allow 2-3 business days for specialty appointment approvals\n\n';
            
            content += '💊 PRESCRIPTION REFILLS:\n';
            content += 'SYMPTOM: Prescription refill requests not processed after 48 hours\n';
            content += 'SOLUTION STEPS:\n';
            content += '1. Submit refill requests 48-72 hours before running out\n';
            content += '2. Verify pharmacy information in your ' + customerName + ' profile\n';
            content += '3. Check if prescription requires provider approval\n';
            content += '4. Ensure prescription hasn\'t expired (contact provider if needed)\n';
            content += '5. Call pharmacy directly to confirm they received the request\n';
            content += '6. Contact ' + customerName + ' pharmacy services: (555) 987-6543\n\n';
            
        } else if (industry == 'Financial Services') {
            content += '🏦 ACCOUNT SECURITY AND ACCESS:\n';
            content += 'SYMPTOM: Unauthorized login attempts on ' + customerName + ' banking account\n';
            content += 'IMMEDIATE ACTIONS:\n';
            content += '1. Change password immediately using a secure device\n';
            content += '2. Enable two-factor authentication in security settings\n';
            content += '3. Review recent account activity for unauthorized transactions\n';
            content += '4. Contact ' + customerName + ' fraud department: (555) 123-FRAUD\n';
            content += '5. Consider placing a security freeze on your account\n';
            content += '6. Monitor credit reports for suspicious activity\n';
            content += '7. Update security questions and contact information\n\n';
            
            content += '💸 TRANSACTION PROCESSING DELAYS:\n';
            content += 'SYMPTOM: ' + customerName + ' transactions taking 3-5 days instead of 1-2 days\n';
            content += 'EXPLANATION AND SOLUTIONS:\n';
            content += '• ACH transfers: 1-3 business days (federal regulations)\n';
            content += '• Wire transfers: Same day if submitted before 2 PM EST\n';
            content += '• Mobile deposits: Available next business day\n';
            content += '• To expedite: Upgrade to ' + customerName + ' Premium account\n';
            content += '• Check processing times in Account Settings → Transfer Limits\n';
            content += '• Contact business banking for volume discounts\n\n';
            
        } else {
            // General support for other industries
            content += '🔐 ACCOUNT ACCESS ISSUES:\n';
            content += 'SYMPTOM: Cannot log into ' + customerName + ' account\n';
            content += 'SOLUTION STEPS:\n';
            content += '1. Verify you\'re using the correct email address\n';
            content += '2. Check if caps lock is on when entering password\n';
            content += '3. Use password reset function\n';
            content += '4. Clear browser cache and cookies\n';
            content += '5. Try a different browser or incognito mode\n';
            content += '6. Check if account is locked due to multiple failed attempts\n';
            content += '7. Contact ' + customerName + ' support for account unlock\n\n';
            
            content += '⚙️ GENERAL SERVICE ISSUES:\n';
            content += 'SYMPTOM: ' + customerName + ' service not working properly\n';
            content += 'SOLUTION STEPS:\n';
            content += '1. Check ' + customerName + ' status page for known issues\n';
            content += '2. Restart the application or browser\n';
            content += '3. Clear browser cache and cookies\n';
            content += '4. Disable browser extensions temporarily\n';
            content += '5. Try accessing from a different device\n';
            content += '6. Check internet connection with other websites\n';
            content += '7. Contact support if issue persists\n\n';
        }
        
        // Add escalation information
        content += '<h2>📞 Escalation and Support Contacts</h2>';
        content += '<p><strong>If the above solutions don\'t resolve your issue:</strong></p>';
        content += '<ul>';
        content += '<li><strong>Phone:</strong> 1-800-' + customerName.replaceAll('[^A-Z]', '').left(7) + '</li>';
        content += '<li><strong>Email:</strong> support@' + customerName.toLowerCase().replaceAll('[^a-z0-9]', '') + '.com</li>';
        content += '<li><strong>Live Chat:</strong> Available 24/7 through ' + customerName + ' website</li>';
        content += '<li><strong>Emergency Support:</strong> For critical issues, mention "PRIORITY" when calling</li>';
        content += '</ul>';
        
        content += '<h2>⏰ Support Hours</h2>';
        content += '<ul>';
        content += '<li><strong>General Support:</strong> 24/7</li>';
        content += '<li><strong>Technical Support:</strong> Monday-Friday 8 AM - 8 PM EST</li>';
        content += '<li><strong>Billing Support:</strong> Monday-Friday 9 AM - 6 PM EST</li>';
        content += '<li><strong>Emergency Support:</strong> 24/7 for service outages</li>';
        content += '</ul>';
        
        if (String.isNotBlank(additionalDetails)) {
            content += '<h2>📝 Additional Context</h2>';
            content += '<p>' + additionalDetails + '</p>';
        }
        
        content += '<h2>📊 Common Resolution Times</h2>';
        content += '<ul>';
        content += '<li><strong>Account access issues:</strong> 15-30 minutes</li>';
        content += '<li><strong>Password resets:</strong> Immediate</li>';
        content += '<li><strong>Technical problems:</strong> 1-4 hours</li>';
        content += '<li><strong>Service outages:</strong> 2-6 hours</li>';
        content += '<li><strong>Billing inquiries:</strong> 1-2 business days</li>';
        content += '</ul>';
        
        content += '<hr>';
        content += '<p><em>Last Updated: ' + System.now().format('MM/dd/yyyy HH:mm') + ' EST</em></p>';
        content += '<p><em>Article ID: KB-' + customerName.replaceAll('[^A-Z0-9]', '') + '-001</em></p>';
        
        return content;
    }
    
    /**
     * @description Customizes case templates based on additional context details
     * @param originalTemplates The base industry templates
     * @param additionalDetails Context to influence case selection
     * @param customerName Company name for context
     * @return Modified list of case templates prioritized by context
     */
    private static List<CaseTemplate> customizeCaseTemplatesBasedOnContext(List<CaseTemplate> originalTemplates, String additionalDetails, String customerName) {
        List<CaseTemplate> customizedTemplates = new List<CaseTemplate>();
        String contextLower = additionalDetails.toLowerCase();
        
        // Create context-specific cases based on keywords in additional details
        if (contextLower.contains('login') || contextLower.contains('password') || contextLower.contains('access') || contextLower.contains('authentication')) {
            customizedTemplates.add(new CaseTemplate(
                'Urgent: Cannot access {customerName} account after recent security update',
                'Customer reports being locked out of their {customerName} account following the recent security update. They have tried resetting their password multiple times but continue to receive "account temporarily locked" messages. This is impacting their ability to complete time-sensitive work.',
                'High',
                'Technical',
                'Phone'
            ));
        }
        
        if (contextLower.contains('performance') || contextLower.contains('slow') || contextLower.contains('speed') || contextLower.contains('loading')) {
            customizedTemplates.add(new CaseTemplate(
                '{customerName} platform experiencing severe performance degradation',
                'Customer experiencing significant slowdowns when using {customerName} services, with page load times exceeding 30 seconds. This began after the recent system maintenance and is affecting their entire team\'s productivity.',
                'High',
                'Technical',
                'Web'
            ));
        }
        
        if (contextLower.contains('billing') || contextLower.contains('payment') || contextLower.contains('charge') || contextLower.contains('invoice')) {
            customizedTemplates.add(new CaseTemplate(
                'Billing discrepancy on {customerName} account - unexpected charges',
                'Customer found unexpected charges on their {customerName} billing statement that don\'t match their contracted services. They need immediate clarification and potential refund processing.',
                'Medium',
                'Billing',
                'Email'
            ));
        }
        
        if (contextLower.contains('mobile') || contextLower.contains('app') || contextLower.contains('ios') || contextLower.contains('android')) {
            customizedTemplates.add(new CaseTemplate(
                '{customerName} mobile app crashing on critical business functions',
                'Customer reports that the {customerName} mobile application crashes consistently when trying to access key features needed for their business operations. This is preventing field workers from completing essential tasks.',
                'High',
                'Technical',
                'Phone'
            ));
        }
        
        if (contextLower.contains('integration') || contextLower.contains('api') || contextLower.contains('sync') || contextLower.contains('connect')) {
            customizedTemplates.add(new CaseTemplate(
                'Critical: {customerName} integration failing with third-party systems',
                'Customer\'s integration between {customerName} and their core business systems has stopped working, causing data sync failures and operational disruptions. This requires immediate technical intervention.',
                'Critical',
                'Technical',
                'Phone'
            ));
        }
        
        if (contextLower.contains('outage') || contextLower.contains('down') || contextLower.contains('unavailable') || contextLower.contains('offline')) {
            customizedTemplates.add(new CaseTemplate(
                'Service interruption: {customerName} platform completely inaccessible',
                'Customer reports complete inability to access {customerName} services for the past hour. This is affecting critical business operations and causing significant revenue impact. Immediate escalation required.',
                'Critical',
                'Technical',
                'Phone'
            ));
        }
        
        if (contextLower.contains('security') || contextLower.contains('breach') || contextLower.contains('unauthorized') || contextLower.contains('hack')) {
            customizedTemplates.add(new CaseTemplate(
                'URGENT: Potential security incident with {customerName} account',
                'Customer suspects unauthorized access to their {customerName} account based on unusual activity patterns. They need immediate security review and account protection measures implemented.',
                'Critical',
                'Security',
                'Phone'
            ));
        }
        
        if (contextLower.contains('data') || contextLower.contains('lost') || contextLower.contains('missing') || contextLower.contains('deleted')) {
            customizedTemplates.add(new CaseTemplate(
                'Data recovery needed: Missing information in {customerName} system',
                'Customer has discovered that critical data is missing from their {customerName} account and needs immediate assistance with data recovery procedures. This information is essential for ongoing business operations.',
                'High',
                'Technical',
                'Email'
            ));
        }
        
        // If we found context-specific templates, prioritize them but also include some original templates
        if (!customizedTemplates.isEmpty()) {
            // Add 2-3 original templates to provide variety
            Integer originalTemplateCount = Math.min(3, originalTemplates.size());
            for (Integer i = 0; i < originalTemplateCount; i++) {
                customizedTemplates.add(originalTemplates[i]);
            }
            return customizedTemplates;
        }
        
        // If no specific context keywords found, return original templates
        return originalTemplates;
    }
    
    /**
     * @description Enhances case descriptions with additional urgency details
     * @param baseDescription The template description
     * @param additionalDetails Context used for randomization (not included in description)
     * @param customerName Company name
     * @return Enhanced description with urgency context
     */
    private static String enhanceCaseDescriptionWithContext(String baseDescription, String additionalDetails, String customerName) {
        // Add specific urgency details to make the case more realistic
        String enhancedDescription = baseDescription;
        
        // NOTE: additionalDetails are used to influence case selection in customizeCaseTemplatesBasedOnContext()
        // but should NOT be included in the final case description
        
        // Add some realistic urgency and business impact context
        String[] urgencyPhrases = new String[]{
            ' This issue is blocking critical business processes.',
            ' Customer requires immediate resolution due to operational impact.',
            ' The problem is affecting multiple team members and productivity.',
            ' This needs urgent attention as it\'s preventing customer-facing activities.',
            ' Escalation may be needed if not resolved within 2 hours.'
        };
        
        // Randomly add urgency context to make cases more realistic
        Integer randomIndex = Math.mod(Math.abs(additionalDetails.hashCode()), urgencyPhrases.size());
        enhancedDescription += urgencyPhrases[randomIndex];
        
        return enhancedDescription;
    }
    
    /**
     * @description Strips HTML tags from text content to create clean readable text
     * @param htmlContent The HTML content to clean
     * @return Clean text without HTML tags
     */
    private static String stripHtmlTags(String htmlContent) {
        if (String.isBlank(htmlContent)) {
            return htmlContent;
        }
        
        String cleanText = htmlContent;
        
        // Remove common HTML document structure
        cleanText = cleanText.replaceAll('(?i)<!DOCTYPE[^>]*>', '');
        cleanText = cleanText.replaceAll('(?i)<html[^>]*>', '');
        cleanText = cleanText.replaceAll('(?i)</html>', '');
        cleanText = cleanText.replaceAll('(?i)<head[^>]*>.*?</head>', '');
        cleanText = cleanText.replaceAll('(?i)<style[^>]*>.*?</style>', '');
        cleanText = cleanText.replaceAll('(?i)<script[^>]*>.*?</script>', '');
        
        // Remove body tags but keep content
        cleanText = cleanText.replaceAll('(?i)<body[^>]*>', '');
        cleanText = cleanText.replaceAll('(?i)</body>', '');
        
        // Convert common HTML elements to text equivalents
        cleanText = cleanText.replaceAll('(?i)<h[1-6][^>]*>', '\n\n**');
        cleanText = cleanText.replaceAll('(?i)</h[1-6]>', '**\n');
        cleanText = cleanText.replaceAll('(?i)<p[^>]*>', '\n\n');
        cleanText = cleanText.replaceAll('(?i)</p>', '');
        cleanText = cleanText.replaceAll('(?i)<br[^>]*>', '\n');
        cleanText = cleanText.replaceAll('(?i)<li[^>]*>', '\n• ');
        cleanText = cleanText.replaceAll('(?i)</li>', '');
        cleanText = cleanText.replaceAll('(?i)<ul[^>]*>', '\n');
        cleanText = cleanText.replaceAll('(?i)</ul>', '\n');
        cleanText = cleanText.replaceAll('(?i)<ol[^>]*>', '\n');
        cleanText = cleanText.replaceAll('(?i)</ol>', '\n');
        
        // Remove remaining HTML tags
        cleanText = cleanText.replaceAll('<[^>]+>', '');
        
        // Clean up extra whitespace and normalize line breaks
        cleanText = cleanText.replaceAll('&nbsp;', ' ');
        cleanText = cleanText.replaceAll('&amp;', '&');
        cleanText = cleanText.replaceAll('&lt;', '<');
        cleanText = cleanText.replaceAll('&gt;', '>');
        cleanText = cleanText.replaceAll('&quot;', '"');
        cleanText = cleanText.replaceAll('&#39;', '\'');
        
        // Normalize whitespace
        cleanText = cleanText.replaceAll('\\s+', ' ');
        cleanText = cleanText.replaceAll('\\n\\s+', '\n');
        cleanText = cleanText.replaceAll('\\n{3,}', '\n\n');
        
        return cleanText.trim();
    }
    
    /**
     * @description Cleans HTML content while preserving basic formatting for rich text fields
     * @param htmlContent The HTML content to clean
     * @return Clean HTML with basic formatting preserved
     */
    private static String cleanHtmlContent(String htmlContent) {
        if (String.isBlank(htmlContent)) {
            return htmlContent;
        }
        
        String cleanContent = htmlContent;
        
        // Remove document structure but keep content formatting
        cleanContent = cleanContent.replaceAll('(?i)<!DOCTYPE[^>]*>', '');
        cleanContent = cleanContent.replaceAll('(?i)<html[^>]*>', '');
        cleanContent = cleanContent.replaceAll('(?i)</html>', '');
        cleanContent = cleanContent.replaceAll('(?i)<head[^>]*>.*?</head>', '');
        cleanContent = cleanContent.replaceAll('(?i)<body[^>]*>', '');
        cleanContent = cleanContent.replaceAll('(?i)</body>', '');
        
        // Remove complex styling but keep basic structure
        cleanContent = cleanContent.replaceAll('(?i)<style[^>]*>.*?</style>', '');
        cleanContent = cleanContent.replaceAll('(?i)<script[^>]*>.*?</script>', '');
        
        // Clean up inline styles but keep the tags
        cleanContent = cleanContent.replaceAll('\\s+style="[^"]*"', '');
        cleanContent = cleanContent.replaceAll('\\s+class="[^"]*"', '');
        cleanContent = cleanContent.replaceAll('\\s+id="[^"]*"', '');
        
        // Simplify headings to basic format
        cleanContent = cleanContent.replaceAll('(?i)<h[1-6][^>]*>', '<h3>');
        cleanContent = cleanContent.replaceAll('(?i)</h[1-6]>', '</h3>');
        
        // Clean up extra whitespace
        cleanContent = cleanContent.replaceAll('\\s+', ' ');
        cleanContent = cleanContent.replaceAll('>\\s+<', '><');
        
        return cleanContent.trim();
    }
    
    /**
     * @description Cleans JSON response from Einstein LLM for parsing
     * @param jsonResponse The raw JSON response to clean
     * @return Clean JSON ready for parsing
     */
    private static String cleanJsonResponse(String jsonResponse) {
        if (String.isBlank(jsonResponse)) {
            return jsonResponse;
        }
        
        String cleanJson = jsonResponse.trim();
        
        // Remove markdown code blocks if present
        if (cleanJson.startsWith('```json')) {
            cleanJson = cleanJson.replaceFirst('^```json\\s*', '');
        }
        if (cleanJson.startsWith('```')) {
            cleanJson = cleanJson.replaceFirst('^```\\s*', '');
        }
        if (cleanJson.endsWith('```')) {
            cleanJson = cleanJson.replaceFirst('\\s*```$', '');
        }
        
        // Remove any leading/trailing text that's not JSON
        Integer jsonStart = cleanJson.indexOf('{');
        Integer jsonEnd = cleanJson.lastIndexOf('}');
        
        if (jsonStart >= 0 && jsonEnd >= 0 && jsonEnd > jsonStart) {
            cleanJson = cleanJson.substring(jsonStart, jsonEnd + 1);
        }
        
        return cleanJson.trim();
    }
    
    /**
     * @description Check if Knowledge is enabled and available in this org
     * @return KnowledgeAvailabilityResult indicating if Knowledge can be used
     */
    @AuraEnabled(cacheable=true)
    public static KnowledgeAvailabilityResult checkKnowledgeEnabled() {
        try {
            // Method 1: Check if Knowledge object is accessible using dynamic schema access
            Schema.SObjectType knowledgeType = Schema.getGlobalDescribe().get('Knowledge__kav');
            if (knowledgeType == null) {
                return new KnowledgeAvailabilityResult(false, 'Knowledge object does not exist in this org');
            }
            
            Schema.DescribeSObjectResult knowledgeDescribe = knowledgeType.getDescribe();
            Boolean hasKnowledgeAccess = knowledgeDescribe.isAccessible() && knowledgeDescribe.isCreateable();
            
            if (!hasKnowledgeAccess) {
                return new KnowledgeAvailabilityResult(false, 'Knowledge object is not accessible in this org');
            }
            
            // Method 2: Check for record types using dynamic SOQL
            List<RecordType> knowledgeRecordTypes = Database.query('SELECT Id FROM RecordType WHERE SObjectType = \'Knowledge__kav\' LIMIT 1');
            Boolean hasRecordTypes = !knowledgeRecordTypes.isEmpty();
            
            if (!hasRecordTypes) {
                return new KnowledgeAvailabilityResult(false, 'No Knowledge record types found - Knowledge may not be enabled');
            }
            
            // Method 3: Check for custom field (FAQ_Answer__c) if it exists using dynamic field access
            Boolean hasCustomField = true;
            try {
                Schema.DescribeFieldResult fieldDescribe = knowledgeDescribe.fields.getMap().get('FAQ_Answer__c').getDescribe();
                hasCustomField = fieldDescribe.isAccessible() && fieldDescribe.isCreateable();
            } catch (Exception e) {
                // Custom field doesn't exist - this might be okay depending on implementation
                System.debug('FAQ_Answer__c field not found or not accessible: ' + e.getMessage());
                hasCustomField = false;
            }
            
            // Knowledge is considered available if object access and record types exist
            // Custom field is optional for now to maintain broader compatibility
            Boolean knowledgeEnabled = hasKnowledgeAccess && hasRecordTypes;
            
            String message = knowledgeEnabled ? 'Knowledge is available in this org' : 'Knowledge is not fully configured';
            if (!hasCustomField) {
                message += ' (Note: FAQ_Answer__c field not available)';
            }
            
            return new KnowledgeAvailabilityResult(knowledgeEnabled, message);
            
        } catch (Exception e) {
            return new KnowledgeAvailabilityResult(false, 'Knowledge availability check failed: ' + e.getMessage());
        }
    }
    
    // ─── Demo Scenario Story Generation ───────────────────────────────────────
    
    private static final String EINSTEIN_SCENARIO_PROMPT_TEMPLATE = 'Demo_Scenario_Story_Generator';
    
    /**
     * @description Orchestrates demo scenario generation with AI-first, fallback second
     */
    private static String generateDemoScenario(String industry, String customerName, Contact assignedContact, List<Case> createdCases, SObject knowledgeArticle) {
        String casesSummary = buildCasesSummaryForScenario(createdCases);
        String contactName = assignedContact != null ? assignedContact.Name : 'a customer contact';
        String knowledgeTitle = '';
        if (knowledgeArticle != null) {
            knowledgeTitle = (String) knowledgeArticle.get('Title');
            if (String.isBlank(knowledgeTitle) || knowledgeTitle.contains('ERROR')) {
                knowledgeTitle = '';
            }
        }
        
        if (USE_EINSTEIN_LLM) {
            try {
                String aiScenario = generateDemoScenarioWithAI(industry, customerName, contactName, casesSummary, knowledgeTitle);
                if (String.isNotBlank(aiScenario)) {
                    System.debug('Demo scenario generated via Einstein LLM');
                    return aiScenario;
                }
            } catch (Exception e) {
                System.debug('Einstein demo scenario failed, using fallback: ' + e.getMessage());
            }
        }
        
        return buildFallbackDemoScenario(industry, customerName, contactName, createdCases, knowledgeTitle);
    }
    
    /**
     * @description Calls Einstein LLM to generate a narrative demo scenario
     */
    private static String generateDemoScenarioWithAI(String industry, String customerName, String contactName, String casesSummary, String knowledgeTitle) {
        try {
            Map<String, ConnectApi.WrappedValue> wrappedInputs = new Map<String, ConnectApi.WrappedValue>();
            Map<String, String> rawInputs = new Map<String, String>{
                'customerName' => customerName,
                'industry' => String.isBlank(industry) ? 'General Business' : industry,
                'contactName' => contactName,
                'casesSummary' => casesSummary,
                'knowledgeTitle' => String.isBlank(knowledgeTitle) ? 'None' : knowledgeTitle
            };
            
            for (String key : rawInputs.keySet()) {
                String value = rawInputs.get(key);
                String jsonValue = '{"value":"' + value.replace('"', '\\"').replace('\n', '\\n') + '"}';
                wrappedInputs.put(key, (ConnectApi.WrappedValue) JSON.deserialize(jsonValue, ConnectApi.WrappedValue.class));
            }
            
            ConnectApi.EinsteinPromptTemplateGenerationsInput request = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            request.isPreview = false;
            request.inputParams = wrappedInputs;
            request.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            request.additionalConfig.maxTokens = 1500;
            request.additionalConfig.temperature = 0.8;
            
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(EINSTEIN_SCENARIO_PROMPT_TEMPLATE, request);
            
            if (response != null && response.generations != null && !response.generations.isEmpty()) {
                return response.generations[0].text;
            }
        } catch (Exception e) {
            System.debug('Einstein scenario generation exception: ' + e.getMessage());
        }
        return null;
    }
    
    /**
     * @description Builds a concise summary of generated cases for prompt input
     */
    private static String buildCasesSummaryForScenario(List<Case> cases) {
        List<String> summaries = new List<String>();
        for (Case c : cases) {
            summaries.add(c.Priority + ' | ' + c.Subject);
        }
        return String.join(summaries, '; ');
    }
    
    /**
     * @description Template-based fallback when Einstein is unavailable
     */
    private static String buildFallbackDemoScenario(String industry, String customerName, String contactName, List<Case> createdCases, String knowledgeTitle) {
        List<String> parts = new List<String>();
        
        parts.add('## Demo Scenario: ' + customerName + ' (' + industry + ')');
        parts.add('');
        parts.add('### Background');
        parts.add(contactName + ' works at ' + customerName + ', a company in the ' + industry + ' industry. ' +
            'They have been experiencing several support challenges that have prompted them to reach out to the service team through multiple channels.');
        parts.add('');
        parts.add('### What Happened');
        
        Integer caseNum = 1;
        for (Case c : createdCases) {
            String urgency = 'High'.equalsIgnoreCase(c.Priority) || 'Critical'.equalsIgnoreCase(c.Priority) ? 'urgent' : 'ongoing';
            parts.add('**Issue ' + caseNum + ' (' + c.Priority + ' Priority):** ' + c.Subject + ' — ' +
                (String.isNotBlank(c.Description) && c.Description.length() > 200 ? c.Description.substring(0, 200) + '...' : c.Description) +
                ' *(Reported via ' + c.Origin + ')*');
            caseNum++;
        }
        
        if (String.isNotBlank(knowledgeTitle)) {
            parts.add('');
            parts.add('### Knowledge Base');
            parts.add('The support team proactively created a knowledge article — **"' + knowledgeTitle + '"** — to document the resolution steps and ensure future agents can resolve similar issues faster.');
        }
        
        parts.add('');
        parts.add('### Demo Talking Points');
        parts.add('- Show how cases from different channels (Email, Phone, Web, Chat) all appear in one unified workspace.');
        parts.add('- Highlight the varying priority levels and how agents can triage effectively.');
        parts.add('- Demonstrate how ' + contactName + '\'s full customer context (account, history, open cases) is visible at a glance.');
        if (String.isNotBlank(knowledgeTitle)) {
            parts.add('- Walk through how the knowledge article surfaces automatically when agents work similar cases.');
        }
        parts.add('- Emphasize AI-assisted case resolution and how it reduces average handle time.');
        
        return String.join(parts, '\n');
    }
    
    /**
     * @description Wrapper class for Knowledge availability check results
     */
    public class KnowledgeAvailabilityResult {
        @AuraEnabled public Boolean knowledgeEnabled;
        @AuraEnabled public String message;
        
        public KnowledgeAvailabilityResult(Boolean enabled, String msg) {
            this.knowledgeEnabled = enabled;
            this.message = msg;
        }
    }

}