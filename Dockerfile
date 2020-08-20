# Specify the version of Swift to use
FROM swift:5.2

# Copy all the files from the host into the container
WORKDIR /src
COPY . .
RUN chmod +x entrypoint.sh
COPY entrypoint.sh /entrypoint.sh

# Build
RUN swift build -c release
RUN cp -f .build/release/mariachi /bin/mariachi

# Specify the container's entrypoint as the action
ENTRYPOINT ["/entrypoint.sh"]
