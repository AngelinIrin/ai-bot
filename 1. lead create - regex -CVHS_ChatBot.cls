public with sharing class CVHS_ChatBot {
    private static final String MODEL_NAME = 'sfdc_ai__DefaultGPT35Turbo';

    @AuraEnabled
    public static String getChatResponse(String userMessage) {
        try {
            // Check if the user wants to enroll
            if (userMessage != null && userMessage.toLowerCase().contains('enroll')) {
                return 'Please provide your name, email, and phone number to proceed with enrollment.';
            }

            // Check for details in the message
            String leadResponse = extractLeadDetails(userMessage);
            if (leadResponse != null) {
                return leadResponse;
            }

            // Construct the chat message based on user input
            List<ChatMessage> messages = new List<ChatMessage>();
            messages.add(new ChatMessage('user', userMessage));

            // Send the request to the API and get the response
            String responseContent = sendChatRequest(messages);
            System.debug('responseContent: ' + responseContent);
            return responseContent != null ? responseContent : 'No response generated.';
        } catch (Exception e) {
            System.debug('Error generating chat response: ' + e.getMessage());
            return 'An error occurred while processing your message.';
        }
    }

    private static String extractLeadDetails(String userMessage) {
        // Regex patterns to capture name, email, and phone
        String namePattern = '([A-Za-z]+\\s[A-Za-z]+)'; // Simple name capture (first last)
        String emailPattern = '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}';
        String phonePattern = '(\\+?[0-9]{1,3}[- ]?)?[0-9]{10}';

        // Extract using regex
        Pattern nameRegEx = Pattern.compile(namePattern);
        Pattern emailRegEx = Pattern.compile(emailPattern);
        Pattern phoneRegEx = Pattern.compile(phonePattern);

        Matcher nameMatcher = nameRegEx.matcher(userMessage);
        Matcher emailMatcher = emailRegEx.matcher(userMessage);
        Matcher phoneMatcher = phoneRegEx.matcher(userMessage);

        // Validate and capture details
        if (nameMatcher.find() && emailMatcher.find() && phoneMatcher.find()) {
            String name = nameMatcher.group(1);
            String email = emailMatcher.group();
            String phone = phoneMatcher.group();

            // Create lead and return response
            return createLead(name, email, phone);
        }
        return null; // No valid details found
    }

    // Helper method to send chat requests to the API
    private static String sendChatRequest(List<ChatMessage> messages) {
        aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();
        aiplatform.ModelsAPI.createChatGenerations_Request request = 
            new aiplatform.ModelsAPI.createChatGenerations_Request();
        aiplatform.ModelsAPI_ChatGenerationsRequest body = 
            new aiplatform.ModelsAPI_ChatGenerationsRequest();

        request.modelName = MODEL_NAME;
        body.messages = new List<aiplatform.ModelsAPI_ChatMessageRequest>();

        // Convert chat messages to API message requests
        for (ChatMessage msg : messages) {
            aiplatform.ModelsAPI_ChatMessageRequest messageRequest = 
                new aiplatform.ModelsAPI_ChatMessageRequest();
            messageRequest.content = msg.message;
            messageRequest.role = msg.role;
            body.messages.add(messageRequest);
        }

        request.body = body;

        try {
            // Make the API call and get the response
            aiplatform.ModelsAPI.createChatGenerations_Response response = 
                modelsAPI.createChatGenerations(request);

            // Return the content of the first response
            if (response?.Code200?.generationDetails?.generations != null &&
                !response.Code200.generationDetails.generations.isEmpty()) {
                return response.Code200.generationDetails.generations[0].content;
            } else {
                return 'No response generated.';
            }
        } catch (aiplatform.ModelsAPI.createChatGenerations_ResponseException e) {
            System.debug('API Error: ' + e.getMessage());
            return 'Error retrieving response: ' + e.getMessage();
        }
    }

    // Method to create a Lead record
    @AuraEnabled
    public static String createLead(String name, String email, String phone) {
        try {
            Lead newLead = new Lead();
            newLead.LastName = name; // You may want to split the name into first and last
            newLead.Email = email;
            newLead.Phone = phone;
            insert newLead; // Insert the lead record
            
            return 'Lead created successfully with ID: ' + newLead.Id;
        } catch (DmlException e) {
            System.debug('Error creating lead: ' + e.getMessage());
            return 'Error creating lead: ' + e.getMessage();
        }
    }

    // Inner class to represent chat messages
    public class ChatMessage {
        public String role;
        public String message;

        public ChatMessage(String role, String message) {
            this.role = role;
            this.message = message;
        }
    }
}
