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

source "docker" "rocky" {
  commit      = "true"
  image       = "rockylinux:9.3"
  run_command = ["-d", "-i", "-t", "--name", "${var.ansible_host}", "{{ .Image }}", "/bin/bash"]
}

build {
  sources = ["source.docker.rocky"]

  provisioner "shell" {
    inline = ["dnf install python 'dnf-command(config-manager)' -y"]
  }

  provisioner "ansible" {
    extra_arguments = ["--extra-vars", "ansible_host=${var.ansible_host} ansible_connection=${var.ansible_connection}"]
    playbook_file   = "../ansible/vnc-image.yml"
    user            = "root"
  }

  post-processors {
    post-processor "docker-tag" {
      repository = "${var.docker_repository}"
      tags       = ["${var.docker_tag}"]
    }
    post-processor "docker-push" {
    }
  }
}
