packer {
  required_plugins {
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1"
    }
  }
}

variable "ansible_connection" {
  type    = string
  default = "docker"
}

variable "ansible_host" {
  type    = string
  default = "default"
}

variable "docker_repository" {
  type    = string
  default = "ghcr.io/nesi/nesi-ondemand-vnc"
}

variable "docker_tag" {
  type    = string
  default = "latest"
}

variable "docker_username" {
    type = string
}

variable "docker_password" {
    type      = string
    sensitive = true
}

variable "docker_server" {
    type    = string
    default = "ghcr.io"
}

source "docker" "rocky93" {
  commit      = "true"
  image       = "rockylinux:9.3"
  run_command = ["-d", "-i", "-t", "--name", "${var.ansible_host}", "{{ .Image }}", "/bin/bash"]
}

build {
  sources = ["source.docker.rocky93"]

  provisioner "shell" {
    inline = ["dnf install python 'dnf-command(config-manager)' -y"]
  }

  provisioner "ansible" {
    extra_arguments = ["--extra-vars", "ansible_host=${var.ansible_host} ansible_connection=${var.ansible_connection}"]
    playbook_file   = "../ansible/base-image.yml"
    user            = "root"
  }

  post-processors {
    post-processor "docker-tag" {
      repository = "${var.docker_repository}"
      tags       = ["${var.docker_tag}"]
    }
    post-processor "docker-push" {
      login          = true
      login_username = "${var.docker_username}"
      login_password = "${var.docker_password}"
      login_server   = "${var.docker_server}"
    }
  }
}
