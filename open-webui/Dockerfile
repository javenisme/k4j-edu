FROM ghcr.io/open-webui/open-webui:v0.8.10

# Copy the patch script
COPY ./patch-openwebui.sh /tmp/patch-openwebui.sh

# Run the patch script before starting the app
RUN chmod +x /tmp/patch-openwebui.sh && /tmp/patch-openwebui.sh

# Run the original entrypoint
CMD ["bash", "start.sh"]
