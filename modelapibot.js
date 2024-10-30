import { LightningElement, track } from 'lwc';
import createChatGenerations from '@salesforce/apex/CVHS_ChatBot.getChatResponse';

export default class Modelapibot extends LightningElement {
    @track userInput = '';
    @track chatMessages = []; // Array to hold chat messages
    @track isLoading = false; // Loading state for spinner

    // Handle input change
    handleInputChange(event) {
        this.userInput = event.target.value;
    }

    // Handle Send button click
    async handleSendMessage() {
        // Check if user input is empty
        if (!this.userInput.trim()) {
            return; // Prevent sending empty messages
        }

        // Add the user's message to the chat messages array
        this.chatMessages.push({ role: 'user', message: this.userInput });
        
        // Set loading state to true before sending the request
        this.isLoading = true;

        try {
            // Call Apex method to get the response
            const response = await createChatGenerations({
                userMessage: this.userInput,
            });

            // Add the response to the chat messages array
            this.chatMessages.push({ role: 'assistant', message: response || 'No response received.' });
        } catch (error) {
            console.error('Error fetching chat response:', error);
            this.chatMessages.push({ role: 'assistant', message: 'An error occurred while processing your message.' });
        } finally {
            // Reset loading state and clear user input
            this.isLoading = false;
            this.userInput = '';
        }
    }

    // Computed property to format chat messages with role labels
    get formattedChatMessages() {
        return this.chatMessages.map(msg => {
            return {
                ...msg,
                label: msg.role === 'user' ? 'You' : 'Assistant'
            };
        });
    }

    handleClearMessages() {
        this.chatMessages = []; // Reset the chat messages array
    }
}
