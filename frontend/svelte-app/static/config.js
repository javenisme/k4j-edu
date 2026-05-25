/**
 * LAMB Frontend Configuration
 *
 * This file is a template. At container startup, envsubst replaces
 * the placeholders with actual environment variable values.
 *
 * Set these environment variables in your Railway service settings:
 *   API_BASE_URL       - Backend API URL (e.g., https://k4j-edu-api.up.railway.app/creator)
 *   LAMB_SERVER_URL    - Backend server URL (e.g., https://k4j-edu-api.up.railway.app)
 *   OPENWEBUI_URL      - Open WebUI URL (e.g., https://k4j-edu-owi.up.railway.app)
 *   KB_SERVER_URL      - KB server URL (e.g., https://k4j-edu-api.up.railway.app/kb)
 */
window.LAMB_CONFIG = {
  api: {
    baseUrl: '${API_BASE_URL}',
    lambServer: '${LAMB_SERVER_URL}',
    openWebUiServer: '${OPENWEBUI_URL}',
    kbServer: '${KB_SERVER_URL}',
  },
  assets: {
    path: '/static'
  },
  features: {
    enableOpenWebUi: true,
    enableDebugMode: false
  }
};
