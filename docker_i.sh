#!/bin/bash

# Function to check if a package is installed
is_installed() {
    dpkg -l | grep -qw "$1"
}

# Function to check if Docker service is running
is_docker_running() {
    sudo systemctl is-active --quiet docker
}

install_docker() {
    echo "Installing Docker..."

    # Update package index
    sudo apt-get update -y

    # Install required packages
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings

    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   
   # Update package index again
   sudo apt-get update

   # Install Docker
   sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Start Docker service
    sudo systemctl start docker
    sudo systemctl enable docker

    echo "Docker installation complete."
}

# Function to change Docker root directory
change_docker_root_dir() {
    local new_root="/DOCKER"

    echo "Changing Docker root directory to $new_root..."

    # Stop Docker service
    sudo systemctl stop docker

    # Create the new Docker root directory if it doesn't exist
    sudo mkdir -p "$new_root"

    # Copy existing Docker data to the new directory
    sudo rsync -a /var/lib/docker/ "$new_root/"

    # Configure Docker to use the new root directory
    echo "{
        \"data-root\": \"$new_root\"
    }" | sudo tee /etc/docker/daemon.json > /dev/null

    # Restart Docker service
    sudo systemctl start docker
    sudo systemctl enable docker

    echo "Docker root directory changed to $new_root."
}

# Function to install Portainer
install_portainer() {
    echo "Installing Portainer..."
    
    # Pull the Portainer image
    # sudo docker pull portainer/portainer-ce
    sudo docker volume create portainer_data
	
    # Run Portainer container
    sudo docker run -d -p 9000:9000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer-ce

    echo "Portainer installation complete."
}

# Main script execution
echo "Starting installation process..."

# Check and install Docker if not installed
if ! is_installed "docker-ce"; then
    install_docker
else
    echo "Docker is already installed."
fi

# Change Docker root directory if it hasn't been changed already
if [ ! -f /etc/docker/daemon.json ] || ! grep -q '"data-root": "/docker"' /etc/docker/daemon.json; then
    change_docker_root_dir
else
    echo "Docker root directory is already set to /DOCKER."
fi

# Check and install Portainer if not installed
if sudo docker ps -q --filter name=portainer; then
    echo "Installing Portainer . . ."
#	install_portainer
else
    echo "Portainer is already installed."
fi

echo "Installation process completed."
